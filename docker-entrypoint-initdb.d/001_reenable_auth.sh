#!/bin/bash

if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
        POSTGRESQL_CONF_DIR=${PGDATA}
fi

# reenable password authentication
sed -i "s/host all all all trust/host all all all md5/" "${POSTGRESQL_CONF_DIR}/pg_hba.conf"
