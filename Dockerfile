ARG PG_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.12.5
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.6.0

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

############################
# Build old versions in a separate stage
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine AS oldversions
ARG PG_VERSION
ARG OSS_ONLY
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
    && cd /build/timescaledb \
    # This script is a bit ugly, but once all the old versions are buildable
    # on PG11, we can remove the 'if' guard
    && echo "if [ \"$(echo ${PG_VERSION} | cut -c1-2)\" != \"11\" ] || [ "\${OLD_VERSION}" \> "1.0.1" ]; then cd /build/timescaledb && rm -fr build && git reset HEAD --hard && git fetch && git checkout \${OLD_VERSION} && ./bootstrap -DPROJECT_INSTALL_METHOD=\"docker\"${OSS_ONLY} && cd build && make install; fi" > ./build_old.sh \
    && chmod +x ./build_old.sh

#####
# Add the latest previous version to the end of the list for each new build
#####
RUN OLD_VERSION=0.10.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=0.10.1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=0.11.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=0.12.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=0.12.1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.0.0-rc1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.0.0-rc2 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.0.0-rc3 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.0.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.0.1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.1.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.1.1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.2.0 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.2.1 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.2.2 /build/timescaledb/build_old.sh
RUN OLD_VERSION=1.3.0 /build/timescaledb/build_old.sh

# Cleanup
RUN \
    # Remove update files and mock files; not needed for old versions
    rm -f $(pg_config --sharedir)/extension/timescaledb--*--*.sql \
    && rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    # Remove all but the last several versiosn ()
    && KEEP_NUM_VERSIONS=6   # This number should be reduced to 5 eventually \
    && rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-*.so | head -n -${KEEP_NUM_VERSIONS}) \
    && rm -f $(ls -1 $(pg_config --sharedir)/extension/timescaledb-*.sql | head -n -${KEEP_NUM_VERSIONS}) \
    # Clean up the rest of the image
    && cd ~ \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine
ARG OSS_ONLY

MAINTAINER Timescale https://www.timescale.com

# Update list above to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.3.1

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

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
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TIMESCALEDB_VERSION} \
    && ./bootstrap -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
