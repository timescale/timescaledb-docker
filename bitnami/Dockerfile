ARG PG_VERSION
############################
# Build tools binaries in separate image
############################
FROM golang:alpine AS tools

ENV TOOLS_VERSION 0.3.0

RUN apk update && apk add --no-cache git \
    && mkdir -p ${GOPATH}/src/github.com/timescale/ \
    && cd ${GOPATH}/src/github.com/timescale/ \
    && git clone https://github.com/timescale/timescaledb-tune.git \
    && git clone https://github.com/timescale/timescaledb-parallel-copy.git \
    # Build timescaledb-tune
    && cd timescaledb-tune/cmd/timescaledb-tune \
    && git fetch && git checkout --quiet $(git describe --abbrev=0) \
    && go get -d -v \
    && go build -o /go/bin/timescaledb-tune \
    # Build timescaledb-parallel-copy
    && cd ${GOPATH}/src/github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy \
    && git fetch && git checkout --quiet $(git describe --abbrev=0) \
    && go get -d -v \
    && go build -o /go/bin/timescaledb-parallel-copy

FROM bitnami/postgresql:${PG_VERSION}
ARG PG_VERSION

MAINTAINER Timescale https://www.timescale.com

# Update list below to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.1.1

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/

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
    && OLD_VERSIONS_PRE11="0.10.0 0.10.1 0.11.0 \
    0.12.0 0.12.1 1.0.0-rc1 1.0.0-rc2 1.0.0-rc3 \
    1.0.0 1.0.1 1.1.0" \
    && OLD_VERSIONS_11="" \
    && OLD_VERSIONS="${OLD_VERSIONS_11}" \
    && if [ "$(echo ${PG_VERSION} | cut -c1-2)" != "11" ]; then \
        OLD_VERSIONS="${OLD_VERSIONS_PRE11} ${OLD_VERSIONS_11}"; \
    fi \
    && for VERSION in ${OLD_VERSIONS}; do \
        cd /build/timescaledb \
        && rm -fr build && git checkout ${VERSION} \
        && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" \
        && cd build && make install; \
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
