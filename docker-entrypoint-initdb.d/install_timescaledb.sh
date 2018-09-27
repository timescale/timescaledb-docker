#!/bin/bash

TS_TELEMETRY='basic'
if [ "${TIMESCALEDB_TELEMETRY}" == "off" ]; then
	TS_TELEMETRY='off'
fi

echo "timescaledb.telemetry_level=${TS_TELEMETRY}" >> ${PGDATA}/postgresql.conf

# create extension timescaledb in initial databases
psql -U "${POSTGRES_USER}" postgres -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -U "${POSTGRES_USER}" template1 -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

if [ "$POSTGRES_DB" != 'postgres' ]; then
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
fi
