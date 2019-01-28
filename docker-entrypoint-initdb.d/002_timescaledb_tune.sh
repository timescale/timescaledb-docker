#!/bin/bash

if [ -z "${PGDATA}" ] && [ ! -z "${BITNAMI_IMAGE_VERSION}" ]; then
	PGDATA=${POSTGRESQL_DATA_DIR}
fi

# Tune database using timescaledb-tune
/usr/local/bin/timescaledb-tune --quiet --yes --conf-path="${PGDATA}/postgresql.conf"
