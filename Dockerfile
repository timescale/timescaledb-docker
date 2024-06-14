ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.18.7
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git gcc musl-dev \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
ARG PREV_IMAGE
FROM ${PREV_IMAGE} AS oldversions

# Remove mock files
RUN rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine3.20
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"


ARG PG_VERSION
RUN set -ex; \
    apk update; \
    apk add --no-cache \
        postgresql${PG_VERSION}-plpython3

ARG PGVECTOR_VERSION
RUN set -ex; \
    apk update; \
    apk add --no-cache --virtual .vector-deps \
        postgresql${PG_VERSION}-dev \
        git \
        build-base \
        clang15 \
        llvm15-dev \
        llvm15; \
    git clone --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git /build/pgvector; \
    cd /build/pgvector; \
    make; \
    make install; \
    apk del .vector-deps

# install pgai only on pg16+ and not on 32 bit arm
ARG PGAI_VERSION
ARG PG_MAJOR_VERSION
ARG TARGETARCH
RUN set -ex; \
    if [ "$PG_MAJOR_VERSION" -gt 15 ] && [ "$TARGETARCH" != "arm" ]; then \
        apk update; \
        apk add --no-cache --virtual .pgai-deps \
            git \
            build-base \
            cargo \
            python3-dev \
            py3-pip; \
        git clone --branch ${PGAI_VERSION} https://github.com/timescale/pgai.git /build/pgai; \
        cp /build/pgai/ai--*.sql /usr/local/share/postgresql/extension/; \
        cp /build/pgai/ai.control /usr/local/share/postgresql/extension/; \
        pip install --verbose --break-system-packages -r /build/pgai/requirements.txt; \
        apk del .pgai-deps; \
    fi

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

ARG TS_VERSION
RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                git \
                openssl \
                openssl-dev \
                tar \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    && apk add --no-cache --virtual .build-deps \
                coreutils \
                dpkg-dev dpkg \
                gcc \
                krb5-dev \
                libc-dev \
                make \
                cmake \
                util-linux-dev \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
