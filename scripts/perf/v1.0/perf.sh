#!/bin/bash -x

function load_params {
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
	total_trace_size=0
}

function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$no_events_expected,$total_trace_size,$delay,$no_thread,$sample_size,$no_repetitions" >> ${prog_name}_${tracer_name}.csv
}

function clean {
	sudo rm sample
	sudo rm statistics
	sudo rm perf.data*
	sudo rm perf.out
	sudo rm ${prog_name}.out
}

function run {
	sudo perf record -e 'syscalls:sys_enter_getuid,syscalls:sys_exit_getuid' $cmd > ${prog_name}.out 2>perf.out
	pid=$(cut -d " " -f2 < ${prog_name}.out)
	no_events=$(sudo grep Processed < perf.out | cut -d ' ' -f2)
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
	rm getuid_pthread_${tracer_name}_*.csv
}

cd $(dirname $0)
prog_name=getuid_pthread
tracer_name=perf
syscall=getuid
no_cpus=$(nproc)
cpu_max=$(($no_cpus - 1))


change_cpus_governor_cmd=../../change_cpus_governor/v1.0/change_cpus_governor.sh
prog_path=../../../load/getuid_pthread/v2.0/
make -C $prog_path
mv $prog_path/getuid_pthread .
#Create directory where traces are written
$change_cpus_governor_cmd performance
load_params
#perform experiment
for t in $(seq 1 $no_repetitions); do
	#print to file csv field names
	echo "mean,std,no_lost_events,no_events_expected,trace_size,delay,no_thread,sample_size,no_repetitions" > ${prog_name}_${tracer_name}.csv
	for no_thread in $no_threads; do
		for sample_size in $sample_sizes; do
			for delay in $delays; do
				cmd="./$prog_name -d $delay -s $sample_size -t $no_thread"
				no_events_expected=$((2 * $sample_size + 2 * $no_thread))
				run
			done
		done
	done
	mv getuid_pthread_${tracer_name}.csv getuid_pthread_${tracer_name}_$t.csv
done
rm getuid_pthread
process_results
$change_cpus_governor_cmd powersave
