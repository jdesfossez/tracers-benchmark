#!/bin/bash -x

cd $(dirname $0)/..

if [ ! -d results ]; then
    mkdir results
fi

if [ ! -f getuid_pthread ];then
    make
fi

prog_name=getuid_pthread
tracer_name=lttng
syscall=getuid

no_threads=($(grep no_thread < param))
no_threads=${no_threads[@]:1}
sample_sizes=($(grep sample_size < param))
sample_sizes=${sample_sizes[@]:1}
outputs=($(grep output < param))
outputs=${outputs[@]:1}
overflows=($(grep overflow < param))
overflows=${overflows[@]:1}
num_subbufs=($(grep num_subbuf < param))
num_subbufs=${num_subbufs[@]:1}
subbuf_sizes=($(grep subbuf_size < param))
subbuf_sizes=${subbuf_sizes[@]:1}

if [ ! -d traces ]; then
	mkdir traces
fi

echo "mean,std,no_lost_events,output,overflow,num_subbuf,subbuf_size,no_thread,sample_size" > results/${prog_name}_${tracer_name}.csv
function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$output,$overflow,$num_subbuf,$subbuf_size,$no_thread,$sample_size" >> results/${prog_name}_${tracer_name}.csv
}

function clean {
	rm -r traces/*
	rm sample
	rm statistics
}

for no_thread in $no_threads; do
	for sample_size in $sample_sizes; do
		cmd="./$prog_name -s $sample_size -t $no_thread"
		for output in $outputs; do
			for overflow in $overflows; do
				for num_subbuf in $num_subbufs; do
					for subbuf_size in $subbuf_sizes; do
						lttng create bm_session -o traces/
						lttng enable-channel -k channel0 --output $output --$overflow --subbuf-size $(($subbuf_size * 1024)) --num-subbuf $num_subbuf
						lttng enable-event --kernel --syscall $syscall -c channel0
						lttng start
						$cmd
						lttng stop
						lttng destroy
						no_events=$(babeltrace traces/kernel/ 2>/dev/null | grep $syscall | wc -l)
						no_lost_events=$((2 * $sample_size + 2 * $no_thread - $no_events))
						save_stats
						clean
					done
				done
			done
		done
	done
done

rm -r traces
