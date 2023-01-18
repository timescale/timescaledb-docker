#!/usr/bin/env bash

# We have to use the bitnami configuration variable to add timescaledb to
# shared preload list, or else it gets overwritten.
if [ -z "$POSTGRESQL_SHARED_PRELOAD_LIBRARIES" ]
then
    POSTGRESQL_SHARED_PRELOAD_LIBRARIES=timescaledb
else
    POSTGRESQL_SHARED_PRELOAD_LIBRARIES="$POSTGRESQL_SHARED_PRELOAD_LIBRARIES,timescaledb"
fi
export POSTGRESQL_SHARED_PRELOAD_LIBRARIES

# Fall through to the original entrypoint.
/opt/bitnami/scripts/postgresql/entrypoint.sh "$@"
