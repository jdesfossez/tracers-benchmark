#!/bin/bash -x

function compute_trace_size {
	total_trace_size=0
	for cpu in $(seq 0 $cpu_max); do
		trace_size=$(ls -l traces/kernel | grep channel0_$cpu | tr -s " " | cut -d" " -f5)
		total_trace_size=$(($total_trace_size + $trace_size))
	done
	total_trace_size=$(($total_trace_size / 1024))
}

function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$frac_lost_events,$total_trace_size,$output,$overflow,$num_subbuf,$total_buf_size,$delay,$no_thread,$sample_size,$no_repetitions" >> ${prog_name}_${tracer_name}.csv
}

function clean {
	rm -r traces/*
	rm sample
	rm statistics
}

function run {
	lttng create bm_session -o traces/
	lttng enable-channel -k channel0 --output $output --$overflow --subbuf-size $(($subbuf_size * 1024)) --num-subbuf $num_subbuf
	lttng enable-event --kernel --syscall $syscall -c channel0
	lttng add-context -k -t pid -c channel0
	lttng start
	pid=$($cmd | cut -d " " -f2)
	lttng stop
	echo $(lttng view 2>&1 >/dev/null | grep discarded | cut -d" " -f4 | tr "\n" "+"| sed "s/.$//") | bc
	lttng destroy
	no_events=$(babeltrace traces/kernel/ 2>/dev/null | grep $syscall | grep "pid = $pid" | wc -l)
	frac_lost_events=$(echo "scale=3;$(( $no_events_expected - $no_events)) / $no_events_expected" | bc -l)
	compute_trace_size
	save_stats
	clean
}

function process_results {
	Rscript average_results.R $no_repetitions
	rm getuid_pthread_lttng_*.csv
}

cd $(dirname $0)
prog_name=getuid_pthread
tracer_name=lttng
syscall=getuid
page_size=$(getconf PAGE_SIZE)
page_size=$(($page_size / 1024))
let cpu_max=($(nproc) - 1)
#read parameters
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
no_repetitions=16

change_cpus_governor_cmd=../../change_cpus_governor/v1.0/change_cpus_governor.sh
prog_path=../../../load/getuid_pthread/v2.0/
make -C $prog_path
mv $prog_path/getuid_pthread .
#Create directory where traces are written
if [ ! -d traces ]; then
	mkdir traces
fi
$change_cpus_governor_cmd performance
#perform experiment
for t in $(seq 1 $no_repetitions); do
	#print to file csv field names
	echo "mean,std,frac_lost_events,trace_size,output,overflow,num_subbuf,total_buf_size,delay,no_thread,sample_size,no_repetitions" > ${prog_name}_${tracer_name}.csv
	for no_thread in $no_threads; do
		for sample_size in $sample_sizes; do
			for delay in $delays; do
				cmd="./$prog_name -d $delay -s $sample_size -t $no_thread"
				no_events_expected=$((2 * $sample_size + 2 * $no_thread))
				for output in $outputs; do
					for overflow in $overflows; do
						for total_buf_size in $total_buf_sizes; do
							for num_subbuf in $num_subbufs; do
								subbuf_size=$(($total_buf_size / $num_subbuf))
								if [ "$subbuf_size" -lt "$page_size" ]; then continue; fi;
								run
							done
						done
					done
				done
			done
		done
	done
	mv getuid_pthread_lttng.csv getuid_pthread_lttng_$t.csv
done
rm -r traces
rm getuid_pthread
process_results
$change_cpus_governor_cmd powersave
