#!/bin/bash -x

cd $(dirname $0)

if [ ! -d results ]; then
	mkdir results
fi

scripts/set_cpus_performance.sh performance
make
scripts/calibration.sh
scripts/lttng.sh
scripts/lttng_snapshot.sh
scripts/system_tap.sh
scripts/perf.sh
scripts/ftrace.sh
rm getuid_pthread
scripts/set_cpus_performance.sh powersave
