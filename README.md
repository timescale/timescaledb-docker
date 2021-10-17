<img src="http://www.timescale.com/img/timescale-wordmark-blue.svg" alt="Timescale" width="300"/>

## What is TimescaleDB?

TimescaleDB is an open-source database designed to make SQL scalable
for time-series data. For more information, see
the [Timescale website](https://www.timescale.com).

## How to use this image

This image is based on the
official
[Postgres docker image](https://store.docker.com/images/postgres) so
the documentation for that image also applies here, including the
environment variables one can set, extensibility, etc.

### Starting a TimescaleDB instance

```
$ docker run -d --name some-timescaledb -p 5432:5432 timescale/timescaledb:latest-pg13
```

Then connect with an app or the `psql` client:

```
$ docker run -it --net=host --rm timescale/timescaledb:latest-pg13 psql -h localhost -U postgres
```

You can also connect your app via port `5432` on the host machine.

If you are running your docker image for the first time, you can also set an environmental variable, `TIMESCALEDB_TELEMETRY`, to set the level of [telemetry](https://docs.timescale.com/using-timescaledb/telemetry) in the Timescale docker instance. For example, to turn off telemetry, run:

```
$ docker run -d --name some-timescaledb -p 5432:5432 --env TIMESCALEDB_TELEMETRY=off timescale/timescaledb:latest-pg13
```

Note that if the cluster has previously been initialized, you should not use this environment variable to set the level of telemetry. Instead, follow the [instructions](https://docs.timescale.com/using-timescaledb/telemetry) in our docs to disable telemetry once a cluster is running.

If you are interested in the latest development snapshot of timescaledb there is also a nightly build available under timescaledev/timescaledb:nightly-pg13 (for PG 12, 13 and 14).

### Notes on timescaledb-tune

We run `timescaledb-tune` automatically on container initialization. By default,
`timescaledb-tune` uses system calls to retrieve an instance's available CPU
and memory. In docker images, these system calls reflect the available resources
on the **host**. For cases where a container is allocated all available
resources on a host, this is fine. But many use cases involve limiting the
amount of resources a container (or the docker daemon) can have on the host.
Therefore, this image looks in the cgroups metadata to determine the
docker-defined limit sizes then passes those values to `timescaledb-tune`.

To specify your own limits, use the `TS_TUNE_MEMORY` and `TS_TUNE_NUM_CPUS`
environment variables at runtime:

```
$ docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password -e TS_TUNE_MEMORY=4GB -e TS_TUNE_NUM_CPUS=4 timescale/timescaledb:latest-pg13
```

To specify a maximum number of [background workers](https://docs.timescale.com/getting-started/configuring#workers), use the `TS_TUNE_MAX_BG_WORKERS` environment variable:

```
$ docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password -e TS_TUNE_MAX_BG_WORKERS=16 timescale/timescaledb:latest-pg13
```

To specify a [maximum number of connections](https://www.postgresql.org/docs/current/runtime-config-connection.html), use the `TS_TUNE_MAX_CONNS` environment variable:

```
$ docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password -e TS_TUNE_MAX_CONNS=200 timescale/timescaledb:latest-pg13
```

To not run `timescaledb-tune` at all, use the `NO_TS_TUNE` environment variable:

```
$ docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password -e NO_TS_TUNE=true timescale/timescaledb:latest-pg13
```
