#!/bin/bash -x

cd $(dirname $0)

prog_name=getuid_pthread
tracer_name=lttng
syscall=getuid

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
subbuf_sizes=($(grep subbuf_size < ${tracer_name}.param))
subbuf_sizes=${subbuf_sizes[@]:1}

make

if [ ! -d traces ]; then
	mkdir traces
fi

echo "mean,std,no_lost_events,output,overflow,num_subbuf,subbuf_size,no_thread,sample_size" > ${prog_name}_${tracer_name}.csv
function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$output,$overflow,$num_subbuf,$subbuf_size,$no_thread,$sample_size" >> ${prog_name}_${tracer_name}.csv
}

function clean {
	rm -r traces/*
	rm sample
	rm statistics
}

./set_cpus_performance.sh performance
for no_thread in $no_threads; do
	for sample_size in $sample_sizes; do
		cmd="./$prog_name -s $sample_size -t $no_thread"
		no_events_expected=$((2 * $sample_size + 2 * $no_thread))
		for output in $outputs; do
			for overflow in $overflows; do
				for num_subbuf in $num_subbufs; do
					for subbuf_size in $subbuf_sizes; do
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
						no_lost_events=$(echo "scale=3;$(( $no_events_expected - $no_events)) / $no_events_expected" | bc -l)
						save_stats
						clean
					done
				done
			done
		done
	done
done
./set_cpus_performance.sh powersave
