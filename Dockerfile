ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
ARG ALPINE_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.26.2
# Cross-compile on the build host. Both tools are pure Go, so a static
# binary works on every target platform without QEMU.
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
# go install puts cross-compiled binaries under /go/bin/<os>_<arch>/, so collect them in /out.
RUN apk update && apk add --no-cache git \
    && export CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT#v} \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest \
    && mkdir -p /out && find /go/bin -type f -exec mv {} /out/ \;

############################
# Fetch the sources on the build host. git under QEMU fails intermittently
# with "cannot pread pack file: Bad address".
############################
ARG ALPINE_VERSION
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS pgvector-src
ARG PGVECTOR_VERSION
RUN apk add --no-cache git \
    && git clone --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git /build/pgvector

ARG ALPINE_VERSION
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS timescaledb-src
ARG TS_COMMIT
RUN apk add --no-cache git \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    && cd /build/timescaledb && git checkout ${TS_COMMIT}

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
ARG PREV_IMAGE=postgres:${PG_VERSION}-alpine
FROM ${PREV_IMAGE} AS oldversions

# Remove mock files
RUN rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
ARG ALPINE_VERSION
FROM postgres:${PG_VERSION}-alpine${ALPINE_VERSION}
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"


ARG PG_VERSION
ARG PG_MAJOR_VERSION
ARG ALPINE_VERSION
RUN set -ex; \
    echo "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community/" >> /etc/apk/repositories; \
    apk update; \
    if [ "$PG_MAJOR_VERSION" -ge 16 ] && [ "$PG_MAJOR_VERSION" -lt 18 ] ; then \
        apk add --no-cache postgresql${PG_VERSION}-plpython3; \
    fi

ARG PGVECTOR_VERSION
ARG PG_VERSION
ARG CLANG_VERSION
ARG PG_MAJOR_VERSION
RUN --mount=type=bind,from=pgvector-src,source=/build/pgvector,target=/build/pgvector,rw \
    set -ex; \
    apk update; \
    apk add --no-cache --virtual .vector-deps \
        postgresql${PG_VERSION}-dev \
        build-base \
        clang${CLANG_VERSION} \
        llvm${CLANG_VERSION}-dev \
        llvm${CLANG_VERSION}; \
    cd /build/pgvector; \
    make -j"$(nproc)" OPTFLAGS=""; \
    make install; \
    apk del .vector-deps

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /out/* /usr/local/bin/
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

ARG TS_VERSION
# cmake reads the commit and the previous versions with git, so git stays.
RUN --mount=type=bind,from=timescaledb-src,source=/build/timescaledb,target=/build/timescaledb,rw \
    set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                git \
                openssl \
                openssl-dev \
                tar \
    \
    && apk add --no-cache --virtual .build-deps \
                coreutils \
                dpkg-dev dpkg \
                icu-dev \
                gcc \
                libc-dev \
                make \
                cmake \
                util-linux-dev \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make -j"$(nproc)" install \
    && cd ~ \
    \
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && apk del .fetch-deps .build-deps \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
