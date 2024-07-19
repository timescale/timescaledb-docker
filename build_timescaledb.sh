#!/usr/bin/env bash
set -ex
PG_MAJOR_VERSION=$1
OSS_ONLY=$2

if [ "$PG_MAJOR_VERSION" == "13" ]; then
  versions=("2.4.2" "2.5.0" "2.5.1" "2.5.2" "2.6.0" "2.6.1" "2.7.0" "2.7.1" "2.7.2" "2.8.0" "2.8.1" "2.9.0" "2.9.1" "2.9.2" "2.9.3" "2.10.0" "2.10.1" "2.10.2" "2.10.3" "2.11.0" "2.11.1" "2.11.2" "2.12.0" "2.12.1" "2.12.2" "2.13.0" "2.13.1" "2.14.0" "2.14.1" "2.14.2" "2.15.0" "2.15.1" "2.15.2")
elif [ "$PG_MAJOR_VERSION" == "14" ]; then
  versions=("2.5.0" "2.5.1" "2.5.2" "2.6.0" "2.6.1" "2.7.0" "2.7.1" "2.7.2" "2.8.0" "2.8.1" "2.9.0" "2.9.1" "2.9.2" "2.9.3" "2.10.0" "2.10.1" "2.10.2" "2.10.3" "2.11.0" "2.11.1" "2.11.2" "2.12.0" "2.12.1" "2.12.2" "2.13.0" "2.13.1" "2.14.0" "2.14.1" "2.14.2" "2.15.0" "2.15.1" "2.15.2")
elif [ "$PG_MAJOR_VERSION" == "15" ]; then
  versions=("2.10.0" "2.10.1" "2.10.2" "2.10.3" "2.11.0" "2.11.1" "2.11.2" "2.12.0" "2.12.1" "2.12.2" "2.13.0" "2.13.1" "2.14.0" "2.14.1" "2.14.2" "2.15.0" "2.15.1" "2.15.2")
elif [ "$PG_MAJOR_VERSION" == "16" ]; then
    versions=("2.13.0" "2.13.1" "2.14.0" "2.14.1" "2.14.2" "2.15.0" "2.15.1" "2.15.2")
fi

apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        git \
        openssl \
        openssl-dev \
        tar

mkdir -p /build/
git clone https://github.com/timescale/timescaledb /build/timescaledb

apk add --no-cache --virtual .build-deps \
    coreutils \
    dpkg-dev dpkg \
    gcc \
    krb5-dev \
    libc-dev \
    make \
    cmake \
    util-linux-dev

for version in "${versions[@]}"; do
  echo "$version"
  cd /build/timescaledb && rm -rf build
  git checkout "$version"
  ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY}
  cd build && make install
done

cd ~
if [ "${OSS_ONLY}" != "" ]; then
  rm -f "$(pg_config --pkglibdir)"/timescaledb-tsl-*.so
fi
apk del .fetch-deps .build-deps
rm -rf /build
sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
