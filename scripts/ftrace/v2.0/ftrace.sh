#!/bin/bash

function load_params {
	change_cpus_governor_path=($(grep "change cpu governor path" < ${tracer_name}.param))
	change_cpus_governor_path=${change_cpus_governor_path[@]:4}
    load_path=($(grep "load path:" < ${tracer_name}.param))
    load_path=${load_path[@]:2}
	no_threads=($(grep no_thread < ${tracer_name}.param))
	no_threads=${no_threads[@]:1}
	sample_sizes=($(grep sample_size < ${tracer_name}.param))
	sample_sizes=${sample_sizes[@]:1}
	delays=($(grep delay < ${tracer_name}.param))
	delays=${delays[@]:1}
	no_repetitions=($(grep no_repetition < ${tracer_name}.param))
	no_repetitions=${no_repetitions[@]:1}
}

function compute_trace_size {
	total_trace_size=$(grep bytes < trace.err | tr -s ' ' | cut -d" " -f2 | awk '{s+=$1} END {print s}')
	total_trace_size=$((total_trace_size / 1024))
}

function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$no_events_expected,$total_trace_size,$delay,$no_thread,$sample_size,$no_repetitions" >> ${load_name}_${tracer_name}.csv
}

function clean {
	sudo rm sample
	sudo rm statistics
	sudo rm trace.dat
	sudo rm trace.out
	sudo rm trace.err
}

function run {
	echo "sudo trace-cmd record -e 'syscalls:sys_enter_getuid' -e 'syscalls:sys_exit_getuid' -F -c $cmd 1>trace.out  2>trace.err"
	sudo trace-cmd record -e 'syscalls:sys_enter_getuid' -e 'syscalls:sys_exit_getuid' -F -c $cmd 1>trace.out  2>trace.err
	pid=$(grep "pid:" < trace.out | cut -d" " -f2)
	no_events=$(grep "read events:" < trace.out | cut -d" " -f3 | awk '{s+=$1} END {print s}')
	if [ "$no_events" == "" ]; then no_lost_events=0;
	else
		no_lost_events=$(( $no_events_expected - $no_events ))
	fi
	compute_trace_size
	save_stats
	clean
}

function process_results {
	Rscript average_results.R $no_repetitions
	rm ${load_name}_${tracer_name}_*.csv
}

cd $(dirname $0)
if [ "$1" == "clean" ]; then
    rm *.csv
    exit
fi

load_name=getuid_pthread
tracer_name=ftrace
syscall=getuid
load_params

if [ ! -f "$load_path/$load_name" ]; then make -C $load_path; fi
cp $load_path/$load_name .
$change_cpus_governor_path performance
#perform experiment
for t in $(seq 1 $no_repetitions); do
	#print to file csv field names
	echo "mean,std,no_lost_events,no_events_expected,trace_size,delay,no_thread,sample_size,no_repetitions" > ${load_name}_${tracer_name}.csv
	for no_thread in $no_threads; do
		for sample_size in $sample_sizes; do
			for delay in $delays; do
				cmd="./$load_name -d $delay -s $sample_size -t $no_thread"
				no_events_expected=$((2 * $sample_size + 2 * $no_thread))
				run
			done
		done
	done
	mv ${load_name}_${tracer_name}.csv ${load_name}_${tracer_name}_$t.csv
done
rm $load_name
process_results
$change_cpus_governor_path powersave
