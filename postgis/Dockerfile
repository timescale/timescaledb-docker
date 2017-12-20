ARG PG_VERSION_TAG
FROM timescale/timescaledb:0.8.0-${PG_VERSION_TAG}

MAINTAINER Timescale https://www.timescale.com
ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-2.3.2}

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                tar \
    && apk add --no-cache --virtual .postgis-deps --repository http://nl.alpinelinux.org/alpine/edge/testing \
        geos \
        gdal \
        proj4 \
    && apk add --no-cache --virtual .build-deps --repository http://nl.alpinelinux.org/alpine/edge/testing \
        postgresql-dev \
        perl \
        file \
        geos-dev \
        libxml2-dev \
        gdal-dev \
        proj4-dev \
        gcc g++ \
        make \
    && cd /tmp \
    && wget http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz -O - | tar -xz \
    && chown root:root -R postgis-${POSTGIS_VERSION} \
    && cd /tmp/postgis-${POSTGIS_VERSION} \
    && ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && cd / \
    \
    && rm -rf /tmp/postgis-${POSTGIS_VERSION} \
    && apk del .fetch-deps .build-deps
