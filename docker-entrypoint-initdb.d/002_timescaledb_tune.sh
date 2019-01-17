#!/bin/bash

# Tune database using timescaledb-tune
/usr/local/bin/timescaledb-tune --quiet --yes --conf-path="${PGDATA}/postgresql.conf"
