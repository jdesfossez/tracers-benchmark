#!/bin/bash -x

cd $(dirname $0)

make

prog_name=clock_gettime
sample_size=$1

cmd="./$prog_name -s $sample_size"
sudo perf record -e 'syscalls:sys_enter_getuid,syscalls:sys_exit_getuid' $cmd > ${prog_name}.out

