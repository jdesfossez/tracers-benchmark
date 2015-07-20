#!/bin/bash -x

cd `dirname $0`

sample_size=$1

make

lttng create --snapshot bm_session
lttng enable-event --kernel --syscall clock_gettime
lttng start
./clock_gettime -s $sample_size
lttng stop
lttng destroy
