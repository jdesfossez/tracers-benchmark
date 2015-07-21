#/bin/bash -x

cd $(dirname $0)
exp_path=$(pwd)

function run_scan {
	scan_delay_path=../../scripts/scan_delay/v2.1
	cp scan.param $scan_delay_path/
	./$scan_delay_path/scan_delay.sh
	cp $scan_delay_path/scanned.param .
}

function run_lttng {
	lttng_path=../../scripts/lttng/v5.2
	cp lttng.param $lttng_path
	./$lttng_path/lttng.sh
	mv $lttng_path/getuid_pthread_lttng.csv .
}

function run_plot_R {
	R_path=../../R_analysis/lost_events/v3.0
	cp getuid_pthread_lttng.csv $R_path/results
	cd $R_path
	rm figs/*
	Rscript plot_data.R
	cd $exp_path
	cp -r $R_path/results/figs .
}

if [ "$1" == "scan" ]; then
	run_scan
elif [ "$1" == "lttng" ]; then
	run_lttng
elif [ "$1" == "plot_R" ]; then
	run_plot_R
elif [ "$1" == "full" ]; then
	run_scan
	run_lttng
	run_plot_R
else
	echo "add argument \"scan\", \"lttng\", \"plot_R\" or \"full\""
fi
