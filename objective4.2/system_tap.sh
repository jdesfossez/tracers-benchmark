#!/bin/bash -x

make

prog_name=clock_gettime

echo "probe syscall.getuid {}" > ${prog_name}.stp
echo "probe syscall.getuid.return {}" >> ${prog_name}.stp
stap -g --suppress-time-limits -v ${prog_name}.stp -c "./$prog_name"

