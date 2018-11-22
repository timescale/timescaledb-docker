ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine

MAINTAINER Timescale https://www.timescale.com

ENV TIMESCALEDB_VERSION 1.0.0

COPY docker-entrypoint-initdb.d/000_install_timescaledb.sh /docker-entrypoint-initdb.d/
COPY docker-entrypoint-initdb.d/001_reenable_auth.sh /docker-entrypoint-initdb.d/

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                openssl-dev \
                tar \
    && mkdir -p /build/timescaledb \
    && wget -O /timescaledb.tar.gz https://github.com/timescale/timescaledb/archive/$TIMESCALEDB_VERSION.tar.gz \
    && tar -C /build/timescaledb --strip-components 1 -zxf /timescaledb.tar.gz \
    && rm -f /timescaledb.tar.gz \
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
    && cd /build/timescaledb \
    && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" \
    && cd build && make install \
    && cd ~ \
    \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
