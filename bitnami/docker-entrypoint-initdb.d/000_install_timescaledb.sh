#!/bin/bash

TS_TELEMETRY='basic'
if [ "${TIMESCALEDB_TELEMETRY}" == "off" ]; then
	TS_TELEMETRY='off'
fi

echo "timescaledb.telemetry_level=${TS_TELEMETRY}" >> /opt/bitnami/postgresql/conf/postgresql.conf

# create extension timescaledb in initial databases
psql -U "${POSTGRESQL_USERNAME}" postgres -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -U "${POSTGRESQL_USERNAME}" template1 -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

if [ "$POSTGRESQL_DATABASE" != 'postgres' ]; then
  psql -U "${POSTGRESQL_USERNAME}" "${POSTGRESQL_DATABASE}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
fi
