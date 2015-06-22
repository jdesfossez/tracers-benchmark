#!/bin/bash -x

cd $(dirname $0)

prog_name=clock_gettime
tracer_name=lttng_snapshot
sample_sizes=($(grep sample_size < ${tracer_name}.param))
sample_sizes=${sample_sizes[@]:1}
num_subbufs=($(grep num_subbuf < ${tracer_name}.param))
num_subbufs=${num_subbufs[@]:1}
subbuf_sizes=($(grep subbuf_size < ${tracer_name}.param))
subbuf_sizes=${subbuf_sizes[@]:1}

make

echo "mean,std,num_subbuf,subbuf_size,sample_size" > ${prog_name}_${tracer_name}.csv
function save_stats {
	mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$num_subbuf,$subbuf_size,$sample_size" >> ${prog_name}_${tracer_name}.csv
}

for sample_size in $sample_sizes; do
	cmd="./clock_gettime -s $sample_size"
	for num_subbuf in $num_subbufs; do
		for subbuf_size in $subbuf_sizes; do
			lttng create --snapshot bm_session
			lttng enable-channel -k channel0 --subbuf-size $(($subbuf_size * 1024)) --num-subbuf $num_subbuf
			lttng enable-event --kernel --syscall clock_gettime -c channel0
			lttng start
			$cmd
			lttng stop
			lttng destroy
			save_stats
		done
	done
done
