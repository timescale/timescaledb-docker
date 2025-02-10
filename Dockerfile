ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
ARG ALPINE_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.22.4
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
    if [ "$PG_MAJOR_VERSION" -ge 16 ] ; then \
        apk add --no-cache postgresql${PG_VERSION}-plpython3; \
    fi

ARG PGVECTOR_VERSION
ARG PG_VERSION
ARG CLANG_VERSION
ARG PG_MAJOR_VERSION
RUN set -ex; \
    apk update; \
    if [ "$PG_MAJOR_VERSION" -ge 17 ] ; then \
        apk add --no-cache postgresql-pgvector; \
    else \
        apk add --no-cache --virtual .vector-deps \
            postgresql${PG_VERSION}-dev \
            git \
            build-base \
            clang${CLANG_VERSION} \
            llvm${CLANG_VERSION}-dev \
            llvm${CLANG_VERSION}; \
        git clone --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git /build/pgvector; \
        cd /build/pgvector; \
        make; \
        make install; \
        apk del .vector-deps; \
    fi

# # install pgai only on pg16+ and not on 32 bit arm
# ARG PGAI_VERSION
# ARG PG_MAJOR_VERSION
# ARG TARGETARCH
# RUN set -ex; \
#     if [ "$PG_MAJOR_VERSION" -ge 16 ] && [ "$TARGETARCH" != "arm" ]; then \
#         apk update; \
#         # install shared libraries needed at runtime
#         apk add libarrow libparquet geos py3-pandas; \
#         # install required dependencies for building pyarrow from source
#         apk add --no-cache --virtual .pgai-deps \
#             git \
#             build-base \
#             cargo \
#             cmake \
#             python3-dev \
#             py3-pip \
#             apache-arrow-dev \
#             geos-dev; \
#         if [ "$(pip --version | awk '{print $2; exit}')" \< "23.0.1" ]; then \
#             python3 -m pip install --upgrade pip==23.0.1; \
#         fi; \
#         git clone --branch ${PGAI_VERSION} https://github.com/timescale/pgai.git /build/pgai; \
#         cd /build/pgai; \
#         # note: this is a hack. pyarrow will be built from source, so must be pinned to this arrow version \
#         echo "pyarrow==$(pkg-config --modversion arrow)" > constraints.txt; \
#         export PIP_CONSTRAINT=$(pwd)/constraints.txt; \
#         if [ "$TARGETARCH" == "386" ]; then \
#             # note: pinned because pandas 2.2.0-2.2.3 on i386 is affected by https://github.com/pandas-dev/pandas/issues/59905 \
#             echo "pandas==2.1.4" >> constraints.txt; \
#             export PIP_CONSTRAINT=$(pwd)/constraints.txt; \
#             # note: no prebuilt binaries for pillow on i386 \
#             apk add --no-cache --virtual .pgai-deps-386 \
#                 jpeg-dev \
#                 zlib-dev; \
#         fi; \
#         PG_BIN="/usr/local/bin" PG_MAJOR=${PG_MAJOR_VERSION} ./projects/extension/build.py install; \
#         if [ "$TARGETARCH" == "386" ]; then apk del .pgai-deps-386; fi; \
#         apk del .pgai-deps; \
#     fi

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
