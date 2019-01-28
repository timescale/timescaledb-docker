#!/bin/bash

if [ -z "${PGDATA}" ] && [ ! -z "${BITNAMI_IMAGE_VERSION}" ]; then
	PGDATA=${POSTGRESQL_DATA_DIR}
fi

# reenable password authentication
sed -i "s/host all all all trust/host all all all md5/" "${PGDATA}/pg_hba.conf"
