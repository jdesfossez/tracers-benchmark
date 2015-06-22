#!/bin/bash -x

cd `dirname $0`

make

prog_name=clock_gettime
sample_size=$1

echo "probe syscall.getuid {}" > ${prog_name}.stp
echo "probe syscall.getuid.return {}" >> ${prog_name}.stp
stap -g --suppress-time-limits -v ${prog_name}.stp -c "./$prog_name -s $sample_size"

