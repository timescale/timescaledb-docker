#!/bin/bash

# Checks to support bitnami image with same scripts so they stay in sync
if [ ! -z "${BITNAMI_IMAGE_VERSION:-}" ]; then
	if [ -z "${POSTGRES_USER:-}" ]; then
		POSTGRES_USER=${POSTGRESQL_USERNAME}
	fi

	if [ -z "${POSTGRES_DB:-}" ]; then
		POSTGRES_DB=${POSTGRESQL_DATABASE}
	fi

	if [ -z "${PGDATA:-}" ]; then
		PGDATA=${POSTGRESQL_DATA_DIR}
	fi
fi

if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
	POSTGRESQL_CONF_DIR=${PGDATA}
fi

TS_TELEMETRY='basic'
if [ "${TIMESCALEDB_TELEMETRY:-}" == "off" ]; then
	TS_TELEMETRY='off'
fi

echo "timescaledb.telemetry_level=${TS_TELEMETRY}" >> ${POSTGRESQL_CONF_DIR}/postgresql.conf

# create extension timescaledb in initial databases
psql -U "${POSTGRES_USER}" postgres -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -U "${POSTGRES_USER}" template1 -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
fi
