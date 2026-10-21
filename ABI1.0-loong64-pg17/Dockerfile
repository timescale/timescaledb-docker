ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
ARG ALPINE_VERSION

FROM cr.loongnix.cn/library/postgres:${PG_VERSION}-alpine${ALPINE_VERSION}

ARG TS_VERSION

# 显式指定可用的 ABI 1.0 Alpine 源
RUN echo "http://alpine.loongnix.cn/v3.11/main" > /etc/apk/repositories && \
    echo "http://alpine.loongnix.cn/v3.11/community" >> /etc/apk/repositories

# 安装编译依赖
RUN apk update && apk add --no-cache \
    build-base \
    cmake \
    openssl-dev \
    git

# 编译 TimescaleDB
RUN set -ex \
    && mkdir -p /build \
    && git clone --branch ${TS_VERSION} --depth 1 \
        https://github.com/timescale/timescaledb /build/timescaledb \
    && cd /build/timescaledb \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DREGRESS_CHECKS=OFF \
        -DTAP_CHECKS=OFF \
        -DWARNINGS_AS_ERRORS=OFF \
    && cd build \
    && make -j1 install \
    && cd / \
    && rm -rf /build \
    && apk del build-base cmake openssl-dev

RUN echo "shared_preload_libraries = 'timescaledb'" \
    >> /usr/local/share/postgresql/postgresql.conf.sample
