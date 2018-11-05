ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine

MAINTAINER Timescale https://www.timescale.com

# Update list below to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.0.0

COPY docker-entrypoint-initdb.d/install_timescaledb.sh /docker-entrypoint-initdb.d/
COPY docker-entrypoint-initdb.d/reenable_auth.sh /docker-entrypoint-initdb.d/

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
                libc-dev \
                make \
                cmake \
                util-linux-dev \
    \
    # Build old versions to keep .so and .sql files around \
    && OLD_VERSIONS="0.9.0 0.9.1 0.9.2 \
    0.10.0 0.10.1 0.11.0 0.12.0 0.12.1 \
    1.0.0-rc1 1.0.0-rc2 1.0.0-rc3" \
    && for VERSION in ${OLD_VERSIONS}; do cd /build/timescaledb && rm -fr build && git checkout ${VERSION} && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" && cd build && make install; done \
    \
    # Remove unnecessary update files & mock files \
    && rm -f `pg_config --sharedir`/extension/timescaledb--*--*.sql \
    && rm -f `pg_config --sharedir`/extension/timescaledb*mock*.sql \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TIMESCALEDB_VERSION} \
    && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" \
    && cd build && make install \
    && cd ~ \
    \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
