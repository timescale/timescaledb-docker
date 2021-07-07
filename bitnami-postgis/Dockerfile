ARG PG_VERSION_TAG
FROM timescale/timescaledb:1.4.2-${PG_VERSION_TAG}-bitnami
MAINTAINER Timescale https://www.timescale.com

ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-2.5.2}

ARG PG_VERSION
ENV PG_VERSION ${PG_VERSION}

USER 0

RUN apt-get -y update \
    && apt-get -y install wget gcc make build-essential libxml2-dev libgeos-dev libproj-dev libgdal-dev libjson-c-dev \
    && cd /tmp \
    && wget -q "http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz" \
    && export C_INCLUDE_PATH=/opt/bitnami/postgresql/include/:/opt/bitnami/common/include/ \
    && export LIBRARY_PATH=/opt/bitnami/postgresql/lib/:/opt/bitnami/common/lib/ \
    && export LD_LIBRARY_PATH=/opt/bitnami/postgresql/lib/:/opt/bitnami/common/lib/ \
    && tar zxf postgis-${POSTGIS_VERSION}.tar.gz && cd postgis-${POSTGIS_VERSION} \
    && ./configure --with-pgconfig=/opt/bitnami/postgresql/bin/pg_config \
    && make \
    && make install \
    && apt-get autoremove --purge -y wget gcc make build-essential libxml2-dev libgeos-dev libproj-dev libgdal-dev libjson-c-dev \
    && apt-get -y install libgeos-c1v5 liblwgeom-2.3-0 libgdal20  \
    && apt-get clean -y \
    && cd / \
    && rm -rf \
      "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/*

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/

USER 1001
