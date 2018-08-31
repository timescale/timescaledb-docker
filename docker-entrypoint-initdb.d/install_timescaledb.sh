#!/bin/bash

# create extension timescaledb in initial databases
psql -U postgres postgres -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -U postgres template1 -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

if [ "$POSTGRES_DB" != 'postgres' ]; then
  psql -U postgres ${POSTGRES_DB} -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
fi

