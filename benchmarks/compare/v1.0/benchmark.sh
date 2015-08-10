#!/bin/bash -x

cd $(dirname $0)
if [ "$1" == "clean" ]; then
	rm calibraiton/*
	rm results/*.csv
	rm results/figs/*
	exit
fi
benchmark_path=$(pwd)
tracers="lttng perf ftrace stap"


#----- calibration -----#
calibrate_path=$(grep calibrate_path: < param/benchmark.paths | cut -d' ' -f2)
cp param/calibrate.param $calibrate_path/.
./$calibrate_path/calibrate.sh
mv $calibrate_path/*.csv calibration/
mv $calibrate_path/*.pdf calibration/
mv $calibrate_path/*.result calibration/
#Modify parameter file according to calibration results
while read line; do
    line=($line)
    delays="$delays ${line[3]}"
done < "calibration/calibrate_noth=1.result"
delay_line=$(grep delay < param/benchmark.param)
sed -i "s/$delay_line/delay:$delays/" param/benchmark.param


#----- tracing benchmark -----#
for tracer in $tracers; do
	tracer_path=$(grep ${tracer}_path: < param/benchmark.paths | cut -d' ' -f2)
	cp param/benchmark.param $tracer_path/${tracer}.param
	if [ "$tracer" == "perf" ]; then
		perf_prog_path=$(grep perf_prog_path: < param/benchmark.paths | cut -d' ' -f2)
		echo "perf_path: $perf_prog_path" >> $tracer_path/${tracer}.param
	fi
	./$tracer_path/${tracer}.sh
	cp $tracer_path/*.csv results/
	./$tracer_path/${tracer}.sh clean
done


#----- produce figs with Rscripts -----#
Rscript_path=$(grep R_analysis_path: < param/benchmark.paths | cut -d' ' -f2)
cp calibration/getuid_pthread_calibrate.csv $Rscript_path/results
for tracer in $tracers; do
	cp results/getuid_pthread_${tracer}.csv $Rscript_path/results
done
cd $Rscript_path
rm results/figs/*
Rscript overhead_compare.R
cd $benchmark_path
cp $Rscript_path/results/figs/* results/figs
