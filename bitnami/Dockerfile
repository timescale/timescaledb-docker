ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.19.1
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git gcc \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
ARG PREV_IMAGE
FROM ${PREV_IMAGE} AS oldversions
# Remove update files, mock files, and all but the last 5 .so/.sql files.
# There are three types of SQL files, initialization, upgrade, and downgrade,
# which we have to count separately, but it's hard to match with globs, and
# there are also many upgrade/downgrade files per version, so just keep more of
# them.
USER 0

# Docker COPY needs at least one file to copy. If no source is specified, the
# command fails. Create two '.emptyfile' files here to prevent the
# 'COPY --from=oldversions' command below from failing. The files are removed
# after the copy operation is performed.
#
# When the first image for a PG version is created, PREV_IMAGE is set to the
# bitnami upstream image. Therefore, no TimescaleDB files exist and the
# copy commands would fail.
RUN set +o pipefail \
    && rm -vf $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && rm -vf $(ls -1tr $(pg_config --pkglibdir)/timescaledb-tsl-*.so | head -n -5) \
    && rm -vf $(ls -1tr $(pg_config --pkglibdir)/timescaledb-[0-9]*.so | head -n -5) \
    && rm -vf $(ls -1tr $(pg_config --sharedir)/extension/timescaledb--*.sql | head -n -20) \
    && { ls $(pg_config --sharedir)/extension/timescaledb--*.sql \
      ; ls $(pg_config --pkglibdir)/timescaledb-*.so \
      ; : ; } \
    && touch $(pg_config --sharedir)/extension/.emptyfile \
    && touch $(pg_config --pkglibdir)/.emptyfile

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM bitnami/postgresql:${PG_VERSION}
ARG PG_VERSION

LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /opt/bitnami/postgresql/lib/.emptyfile /opt/bitnami/postgresql/lib/timescaledb-*.so /opt/bitnami/postgresql/lib/
COPY --from=oldversions /opt/bitnami/postgresql/share/extension/.emptyfile /opt/bitnami/postgresql/share/extension/timescaledb--*.sql /opt/bitnami/postgresql/share/extension/
COPY bitnami/timescaledb-bitnami-entrypoint.sh /opt/bitnami/scripts/postgresql/

USER 0
ARG TS_VERSION
RUN set -ex \
    && rm -v /opt/bitnami/postgresql/lib/.emptyfile \
    && rm -v /opt/bitnami/postgresql/share/extension/.emptyfile \
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
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker-bitnami" \
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
        /build \
        "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/*

USER 1001

ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
