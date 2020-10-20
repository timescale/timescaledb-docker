#!/bin/bash

if [ ! -z "${BITNAMI_IMAGE_VERSION:-}" ]; then
	if [ -z "${POSTGRES_REPLICATION_MODE:-}" ]; then
		POSTGRES_REPLICATION_MODE=${POSTGRESQL_REPLICATION_MODE}
	fi

	if [ "${POSTGRES_REPLICATION_MODE:-}" == "slave" ]; then
		echo "exit $0 in slave mode"
		exit 0
	fi
fi



if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
        POSTGRESQL_CONF_DIR=${PGDATA}
fi

# reenable password authentication
sed -i "s/host all all all trust/host all all all md5/" "${POSTGRESQL_CONF_DIR}/pg_hba.conf"
