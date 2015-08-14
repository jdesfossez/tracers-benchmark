#!/bin/bash -x

cd $(dirname $0)
if [ "$1" == "clean" ]; then
	./calibration/calibrate.sh clean
	rm results/*.csv
	rm results/figs/*
	rm load/getuid_pthread
	exit
fi
benchmark_path=$(pwd)
tracers="lttng perf ftrace stap"


#----- calibration -----#
cp param/calibrate.param calibration/
./calibration/calibrate.sh
cp calibration/*.csv results/
rm calibration/calibrate.param
#Modify parameter file according to calibration results
while read line; do
    line=($line)
    delays="$delays ${line[3]}"
done < "calibration/calibrate_noth=1.result"
delay_line=$(grep delay < param/benchmark.param)
sed -i "s/$delay_line/delay:$delays/" param/benchmark.param


#----- tracing benchmark -----#
for tracer in $tracers; do
	cp param/benchmark.param scripts/${tracer}.param
	if [ "$tracer" == "perf" ]; then
		perf_prog_path=$(grep perf_prog_path: < param/benchmark.paths | cut -d' ' -f2)
		echo "perf_path: $perf_prog_path" >> scripts/${tracer}.param
	fi
	./scripts/${tracer}.sh
	cp scripts/*.csv results/
	./scripts/${tracer}.sh clean
	rm scripts/${tracer}.param
done


#----- produce figs with Rscripts -----#
rm results/figs/*
Rscript Rscripts/overhead_compare.R
