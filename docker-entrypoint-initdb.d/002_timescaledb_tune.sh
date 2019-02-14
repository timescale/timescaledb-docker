#!/bin/bash

NO_TS_TUNE=${NO_TS_TUNE:-""}
TS_TUNE_MEMORY=${TS_TUNE_MEMORY:-""}
TS_TUNE_NUM_CPUS=${TS_TUNE_NUM_CPUS:-""}

if [ ! -z "${NO_TS_TUNE}" ]; then
    # The user has explicitly requested not to run timescaledb-tune; exit this script
    exit 0
fi


if [ -z "${PGDATA}" ] && [ ! -z "${BITNAMI_IMAGE_VERSION}" ]; then
    PGDATA=${POSTGRESQL_DATA_DIR}
fi

if [ -z "${TS_TUNE_MEMORY}" ]; then
    # See if we can get the container's total allocated memory from the cgroups metadata
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        TS_TUNE_MEMORY=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        FREE_MB=$(free -m | grep 'Mem' | awk '{print $2}')
        FREE_BYTES=$(( ${FREE_MB} * 1024 * 1024 ))
        if [ ${TS_TUNE_MEMORY} -gt ${FREE_BYTES} ]; then
            # Something weird is going on if the cgroups memory limit exceeds the total available
            # amount of system memory reported by "free", which is the total amount of memory available on the host.
            # Most likely, it is this issue: https://github.com/moby/moby/issues/18087 (if no limit is
            # set, the max limit is set to the max 64 bit integer). In this case, we just leave
            # TS_TUNE_MEMORY blank and let timescaledb-tune derive the memory itself using syscalls.
            TS_TUNE_MEMORY=""
        else
            # Convert the bytes to MB so it plays nicely with timescaledb-tune
            TS_TUNE_MEMORY="$(echo ${TS_TUNE_MEMORY} | awk '{print int($1 / 1024 / 1024)}')MB"
        fi
    fi
fi

if [ -z "${TS_TUNE_NUM_CPUS}" ]; then
    # See if we can get the container's available CPUs from the cgroups metadata
    if [ -f /sys/fs/cgroup/cpuset/cpuset.cpus ]; then
        TS_TUNE_NUM_CPUS=$(cat /sys/fs/cgroup/cpuset/cpuset.cpus)
        if [[ ${TS_TUNE_NUM_CPUS} == *-* ]]; then
            # The CPU limits have been defined as a range (e.g., 0-3 for 4 CPUs). Subtract them and add 1
            # to convert the range to the number of CPUs.
            TS_TUNE_NUM_CPUS=$(echo ${TS_TUNE_NUM_CPUS} | tr "-" " " | awk '{print ($2 - $1) + 1}')
        elif [[ ${TS_TUNE_NUM_CPUS} == *,* ]]; then
            # The CPU limits have been defined as a comma separated list (e.g., 0,1,2,3 for 4 CPUs). Count each CPU
            TS_TUNE_NUM_CPUS=$(echo ${TS_TUNE_NUM_CPUS} | tr "," "\n" | wc -l)
        elif [ $(echo -n ${TS_TUNE_NUM_CPUS} | wc -c) -eq 1 ]; then
            # The CPU limit has been defined as a single numbered CPU. In this case the CPU limit is 1
            # regardless of what that number is
            TS_TUNE_NUM_CPUS=1
        fi
    fi
fi

if [ ! -z "${TS_TUNE_MEMORY}" ]; then
    TS_TUNE_MEMORY_FLAGS=--memory="${TS_TUNE_MEMORY}"
fi

if [ ! -z "${TS_TUNE_NUM_CPUS}" ]; then
    TS_TUNE_NUM_CPUS_FLAGS=--cpus=${TS_TUNE_NUM_CPUS}
fi

/usr/local/bin/timescaledb-tune --quiet --yes --conf-path="${PGDATA}/postgresql.conf" ${TS_TUNE_MEMORY_FLAGS} ${TS_TUNE_NUM_CPUS_FLAGS}
