#!/bin/bash -x

cd `dirname $0`

sample_size=$1

make

if [ ! -d traces ]; then
	mkdir traces
fi

lttng create bm_session -o traces/
lttng enable-event --kernel --syscall clock_gettime
lttng start
./clock_gettime -s $sample_size
lttng stop
lttng destroy
