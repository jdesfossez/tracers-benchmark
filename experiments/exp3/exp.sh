#!/bin/bash

benchmark_path=../../benchmarks/lttng/v1.0
exp_path=$(pwd)

cp calibrate.param $benchmark_path/calibration/
cp lttng.param $benchmark_path/lttng/

cd $benchmark_path
./benchmark.sh

cd $exp_path
cp -r $benchmark_path/calibration .
cp -r $benchmark_path/lttng .
