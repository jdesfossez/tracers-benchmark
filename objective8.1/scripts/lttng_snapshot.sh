#!/bin/bash -x

cd ../$(dirname $0)

if [ ! -d results ]; then
    mkdir results
fi

if [ ! -f getuid_pthread ];then
    make
fi

prog_name=getuid_pthread
tracer_name=lttng_snapshot
syscall=getuid

no_threads=($(grep no_thread < param))
no_threads=${no_threads[@]:1}
sample_sizes=($(grep sample_size < param))
sample_sizes=${sample_sizes[@]:1}
num_subbufs=($(grep num_subbuf < param))
num_subbufs=${num_subbufs[@]:1}
subbuf_sizes=($(grep subbuf_size < param))
subbuf_sizes=${subbuf_sizes[@]:1}

echo "mean,std,num_subbuf,subbuf_size,no_thread,sample_size" > results/${prog_name}_${tracer_name}.csv
function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$num_subbuf,$subbuf_size,$no_thread,$sample_size" >> results/${prog_name}_${tracer_name}.csv
}

for no_thread in $no_threads; do
	for sample_size in $sample_sizes; do
		cmd="./$prog_name -s $sample_size -t $no_thread"
		for num_subbuf in $num_subbufs; do
			for subbuf_size in $subbuf_sizes; do
				lttng create --snapshot bm_session
				lttng enable-channel -k channel0 --subbuf-size $(($subbuf_size * 1024)) --num-subbuf $num_subbuf
				lttng enable-event --kernel --syscall $syscall -c channel0
				lttng start
				$cmd
				lttng stop
				lttng destroy
				save_stats
			done
		done
	done
done
