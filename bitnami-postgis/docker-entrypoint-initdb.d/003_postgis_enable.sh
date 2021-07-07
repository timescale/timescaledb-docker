
# create extension timescaledb in initial databases
psql -U "${POSTGRES_USER}" postgres -c "CREATE EXTENSION IF NOT EXISTS postgis CASCADE;"
psql -U "${POSTGRES_USER}" template1 -c "CREATE EXTENSION IF NOT EXISTS postgis CASCADE;"

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS postgis CASCADE;"
fi
