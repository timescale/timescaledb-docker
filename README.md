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
$ docker run -d --name some-timescaledb -p 5432:5432 timescale/timescaledb
```

Then connect with an app or the `psql` client:

```
$ docker run -it --net=host --rm timescale/timescaledb psql -h localhost -U postgres
```

You can also connect your app via port `5432` on the host machine.

