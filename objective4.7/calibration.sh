#!/bin/bash -x

cd $(dirname $0)

make

sample_size=$1
./clock_gettime -s $1
