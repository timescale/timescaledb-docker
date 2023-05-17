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

# Timescale tuning breaks standby nodes on repmgr clusters, so we disable it
# by default
if [ "$PG_BASE_IMAGE" == "postgresql-repmgr" ]
then
    export NO_TS_TUNE=true
fi

# Fall through to the original entrypoint. Note that we use exec here because
# this wrapper script shouldn't change PID 1 of the container.
exec "${PG_ORIGINAL_ENTRYPOINT_PATH}/entrypoint.sh" "$@"
