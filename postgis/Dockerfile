ARG PG_VERSION_TAG
FROM timescale/timescaledb:2.0.0-beta5-${PG_VERSION_TAG}

LABEL maintainer="Timescale https://www.timescale.com"
ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-2.5.3}

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                tar \
    # add libcrypto from (edge:main) for gdal-2.3.0
    #&& apk add --no-cache --virtual .crypto-rundeps \
    #            --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    #            libressl2.7-libcrypto \
    #            libcrypto1.1 \
    #            poppler \
    #            llvm9-dev \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        file \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        llvm \
        clang \
        clang-dev \
    && apk add --no-cache --virtual .build-deps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        g++ \
        gdal-dev \
        geos-dev \
        proj-dev \
        protobuf-c-dev \
    && cd /tmp \
    && wget https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz -O - | tar -xz \
    && chown root:root -R postgis-${POSTGIS_VERSION} \
    && cd /tmp/postgis-${POSTGIS_VERSION} \
    && ./autogen.sh \
    && ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        geos \
        gdal \
        proj \
        protobuf-c \
        libstdc++ \
    && cd / \
    && rm -rf /tmp/postgis-${POSTGIS_VERSION} \
    && apk del .fetch-deps .build-deps .build-deps-edge
