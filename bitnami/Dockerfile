ARG PG_VERSION
FROM bitnami/postgresql:${PG_VERSION}

MAINTAINER Timescale https://www.timescale.com

# Update list below to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.1.0

COPY docker-entrypoint-initdb.d/000_install_timescaledb.sh /docker-entrypoint-initdb.d/
COPY docker-entrypoint-initdb.d/001_reenable_auth.sh /docker-entrypoint-initdb.d/

USER 0
RUN set -ex \
    && mkdir -p /var/lib/apt/lists/partial \
    && apt-get update \
    && apt-get -y install \
            \
            build-essential \
            libssl-dev \
            git \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
            wget \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    # Build old versions to keep .so and .sql files around \
    && OLD_VERSIONS="0.9.2 0.10.0 0.10.1 0.11.0 \
    0.12.0 0.12.1 \ 1.0.0-rc1 1.0.0-rc2 1.0.0-rc3 1.0.0 1.0.1" \
    && for VERSION in ${OLD_VERSIONS}; do \
        cd /build/timescaledb && \
        rm -fr build && git checkout ${VERSION} && \
        ./bootstrap -DPROJECT_INSTALL_METHOD="docker" && \
        cd build && make install; \
    done \
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
    && apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
    && apt-get clean -y \
    && rm -rf \
      "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/*           \
    \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /opt/bitnami/postgresql/share/postgresql.conf.sample

USER 1001
