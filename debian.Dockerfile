ARG PG_VERSION
ARG PREV_TS_VERSION=1.6.1
ARG PREV_EXTRA
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.14.2
FROM golang:${GO_VERSION}-buster AS tools

ENV TOOLS_VERSION 0.8.1

RUN apt-get update && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/* \
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

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
FROM timescale/timescaledb:${PREV_TS_VERSION}-pg${PG_VERSION}${PREV_EXTRA} AS oldversions
# Remove update files, mock files, and all but the last 5 .so/.sql files
RUN rm -f $(pg_config --sharedir)/extension/timescaledb--*--*.sql \
    && rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-tsl-*.so | head -n -5) \
    && rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-1*.so | head -n -5) \
    && rm -f $(ls -1 $(pg_config --sharedir)/extension/timescaledb-*.sql | head -n -5)

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}
ARG OSS_ONLY

MAINTAINER Timescale https://www.timescale.com

# Update list above to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.7.0

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/share/postgresql/${PG_MAJOR}/extension/

RUN set -ex \
    && apt-get update \
    && apt-get install -y ca-certificates \
                git \
                openssl \
                libssl-dev \
                tar \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    && apt-get install -y coreutils \
                dpkg-dev dpkg \
                gcc \
                libc-dev \
                make \
                cmake \
                util-linux \
                postgresql-server-dev-${PG_MAJOR} \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TIMESCALEDB_VERSION} \
    && ./bootstrap -DREGRESS_CHECKS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/share/postgresql/${PG_MAJOR}/postgresql.conf.sample
