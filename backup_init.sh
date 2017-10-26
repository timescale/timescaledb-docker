#!/bin/bash
set -e

: "${PGDATA:?PGDATA must be set}"

USE_WALE_SIDECAR=${USE_WALE_SIDECAR:-false}
WALE_INIT_LOCKFILE=$PGDATA/wale_init_lockfile
WALE_SIDECAR_HOSTNAME=${WALE_SIDECAR_HOSTNAME:-localhost}
WALE_SIDECAR_PORT=${WALE_SIDECAR_PORT:-5000}
ARCHIVE_COMMAND="archive_command='/usr/bin/wget "${WALE_SIDECAR_HOSTNAME}":"${WALE_SIDECAR_PORT}"/push/%f -O -'"

if [ $USE_WALE_SIDECAR = 'true' ]; then
    touch $WALE_INIT_LOCKFILE

    if [ ! -f $PGDATA/postgresql.conf ] ; then
        echo $ARCHIVE_COMMAND >> /usr/local/share/postgresql/postgresql.conf.sample
    fi

    while [ -f $WALE_INIT_LOCKFILE ] ;
    do
        sleep 2
        echo 'waiting for wal-e startup'
    done

else
   echo "Running without wal-e sidecar"
fi

./docker-entrypoint.sh $@
