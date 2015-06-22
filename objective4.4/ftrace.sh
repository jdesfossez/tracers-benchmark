#!/bin/bash -x

cd $(dirname $0)

make

prog_name=clock_gettime
sample_size=$1

cmd="./$prog_name -s $sample_size"
sudo trace-cmd record -e 'syscalls:sys_enter_clock_gettime' -e 'syscalls:sys_exit_clock_gettime' $cmd > ${prog_name}.out
