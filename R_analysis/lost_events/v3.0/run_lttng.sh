#!/bin/bash -x

cd $(dirname $0)

if [ ! -d results ]; then
	mkdir results
	mkdir results/figs
fi

lttng_path=../../../scripts/lttng/v5.0
if [ -f $lttng_path/lttng.param ]; then
	mv $lttng_path/lttng.param $lttng_path/lttng.param.old
fi
cp lttng.param $lttng_path

$lttng_path/lttng.sh
mv $lttng_path/getuid_pthread_lttng.csv results/

if [ -f $lttng_path/lttng.param.old ]; then
	mv $lttng_path/lttng.param.old $lttng_path/lttng.param
fi
