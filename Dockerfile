# syntax=docker/dockerfile:1

ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
ARG ALPINE_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.22.4
FROM golang:${GO_VERSION} AS tools

ENV TOOLS_VERSION 0.8.1

RUN <<EOT
    apt-get update
    apt-get install -y git gcc
    go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest
    go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest
EOT

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
FROM postgres:${PG_VERSION}-bookworm
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"

SHELL ["/bin/bash", "-eu", "-o", "pipefail", "-c"]

ARG PG_VERSION
ARG PG_MAJOR_VERSION
ARG ALPINE_VERSION
RUN <<EOT
    if [ "$PG_MAJOR_VERSION" -ge 16 ]; then
      apt-get update
      apt-get install -y postgresql-plpython3-${PG_MAJOR_VERSION}
    fi
EOT

ARG PG_MAJOR_VERSION
RUN <<EOT
    apt-get update
    apt-get install -y postgresql-${PG_MAJOR_VERSION}-pgvector;
EOT

# install pgai only on pg16+ and not on 32 bit arm
ARG PGAI_VERSION
ARG PG_MAJOR_VERSION
ARG TARGETARCH
RUN <<EOT
    if [ "$PG_MAJOR_VERSION" -ge 16 ] && [ "$TARGETARCH" != "arm" ]; then
        apt-get update && apt-get install -y git python3 python3-pip
        PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install uv
        git clone --branch ${PGAI_VERSION} https://github.com/timescale/pgai.git /build/pgai
        cd /build/pgai
        PG_BIN="/usr/lib/postgresql/17/bin/" PG_MAJOR=${PG_MAJOR_VERSION} ./projects/extension/build.py build install
        cd ~
        rm -rf /build/pgai
        PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip uninstall -y uv
        apt-get purge -y git python3 python3-pip
        apt-get autoremove -y
    fi
EOT

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
# COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
# COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

ARG TS_VERSION
ARG OSS_ONLY=""
RUN <<EOT
    apt-get update
    deps="ca-certificates git gcc libkrb5-dev libssl-dev libc-dev make postgresql-server-dev-${PG_MAJOR_VERSION} cmake"
    apt-get install -y ${deps}
    mkdir -p /build/
    git clone https://github.com/timescale/timescaledb /build/timescaledb
    # Build current version
    cd /build/timescaledb && rm -fr build
    git checkout ${TS_VERSION}
    ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY}
    cd build && make -j20 install
    cd ~
    if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi
    apt-get purge -y ${deps}
    apt-get autoremove -y
    rm -rf /build
EOT
RUN sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/share/postgresql/postgresql.conf.sample
