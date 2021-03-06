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
	outputs=($(grep output < ${tracer_name}.param))
	outputs=${outputs[@]:1}
	overflows=($(grep overflow < ${tracer_name}.param))
	overflows=${overflows[@]:1}
	num_subbufs=($(grep num_subbuf < ${tracer_name}.param))
	num_subbufs=${num_subbufs[@]:1}
	total_buf_sizes=($(grep total_buf_size < ${tracer_name}.param))
	total_buf_sizes=${total_buf_sizes[@]:1}
	delays=($(grep delay < ${tracer_name}.param))
	delays=${delays[@]:1}
	no_repetitions=($(grep no_repetition < ${tracer_name}.param))
	no_repetitions=${no_repetitions[@]:1}
}

function compute_trace_size {
	total_trace_size=0
	for cpu in $(seq 0 $cpu_max); do
		trace_size=$(ls -l traces/kernel | grep channel0_$cpu$ | tr -s " " | cut -d" " -f5)
		total_trace_size=$(($total_trace_size + $trace_size))
	done
	total_trace_size=$(($total_trace_size / 1024))
}

function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$no_events_expected,$total_trace_size,$output,$overflow,$num_subbuf,$total_buf_size,$delay,$no_thread,$sample_size,$no_repetitions" >> ${load_name}_${tracer_name}.csv
}

function clean {
	rm -r traces/*
	rm sample
	rm statistics
}

function run {
	lttng create bm_session -o traces/
	echo "output: $output, overflow: $overflow, subbuf-size: $subbuf_size(Kb), num-subbuf: $num_subbuf"
	lttng enable-channel -k channel0 --output $output --$overflow --subbuf-size $(($subbuf_size * 1024)) --num-subbuf $num_subbuf
	lttng enable-event --kernel --syscall $syscall -c channel0
	lttng add-context -k -t pid -c channel0
	lttng start
	echo $cmd
	pid=$($cmd | cut -d " " -f2)
	lttng stop
	echo $(lttng view 2>&1 >/dev/null | grep discarded | cut -d" " -f4 | tr "\n" "+"| sed "s/.$//") | bc
	lttng destroy
	no_events=$(babeltrace traces/kernel/ 2>/dev/null | grep $syscall | grep "pid = $pid" | wc -l)
	no_lost_events=$(( $no_events_expected - $no_events ))
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
tracer_name=lttng
syscall=getuid
page_size=$(getconf PAGE_SIZE)
page_size=$(($page_size / 1024))
no_cpus=$(nproc)
cpu_max=$(($no_cpus - 1))
load_params

if [ ! -f "$load_path/$load_name" ]; then make -C $load_path; fi
cp $load_path/$load_name .
#Create directory where traces are written
if [ ! -d traces ]; then
	mkdir traces
fi
$change_cpus_governor_path performance
#perform experiment
for t in $(seq 1 $no_repetitions); do
	#print to file csv field names
	echo "mean,std,no_lost_events,no_events_expected,trace_size,output,overflow,num_subbuf,total_buf_size,delay,no_thread,sample_size,no_repetitions" > ${load_name}_${tracer_name}.csv
	for no_thread in $no_threads; do
		for sample_size in $sample_sizes; do
			for delay in $delays; do
				cmd="./$load_name -d $delay -s $sample_size -t $no_thread"
				no_events_expected=$((2 * $sample_size + 2 * $no_thread))
				for output in $outputs; do
					for overflow in $overflows; do
						for total_buf_size in $total_buf_sizes; do
							for num_subbuf in $num_subbufs; do
								subbuf_size=$(($total_buf_size / $no_cpus / $num_subbuf))
								if [ "$subbuf_size" -lt "$page_size" ]; then continue; fi;
								run
							done
						done
					done
				done
			done
		done
	done
	mv ${load_name}_${tracer_name}.csv ${load_name}_${tracer_name}_$t.csv
done
rm -r traces
rm $load_name
process_results
$change_cpus_governor_path powersave
