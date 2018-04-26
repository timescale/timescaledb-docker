#!/bin/bash
set -e

: "${PGDATA:?PGDATA must be set}"

WGET_BIN=${WGET_BIN:-/usr/bin/wget}
USE_WALE_SIDECAR=${USE_WALE_SIDECAR:-false}
WALE_INIT_LOCKFILE=$PGDATA/wale_init_lockfile
WALE_SIDECAR_HOSTNAME=${WALE_SIDECAR_HOSTNAME:-localhost}
WALE_SIDECAR_PORT=${WALE_SIDECAR_PORT:-5000}
ARCHIVE_COMMAND="archive_command='"${WGET_BIN}" "${WALE_SIDECAR_HOSTNAME}":"${WALE_SIDECAR_PORT}"/push/%f -O -'"

if [ $USE_WALE_SIDECAR = 'true' ]; then
    set +e
    ${WGET_BIN} ${WALE_SIDECAR_HOSTNAME}:${WALE_SIDECAR_PORT}/ping
    if [ $? -ne 0 ] ; then
        echo "Create wal-e lock file"
        touch $WALE_INIT_LOCKFILE
    fi
    set -e

    if [ -f $PGDATA/postmaster.pid ] ; then
        set +e
        pg_isready
        if [ $? -ne 0 ] ; then
            echo "Removing leftover postmaster file"
            rm $PGDATA/postmaster.pid
        fi
        set -e
    fi

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

echo "Launching postgres"
echo "$@"
exec ./docker-entrypoint.sh "$@"
