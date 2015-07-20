#!/bin/bash -x

cd $(dirname $0)/..

if [ ! -d results ]; then
    mkdir results
fi

if [ ! -f getuid_pthread ];then
    make
fi

prog_name=getuid_pthread
tracer_name=calibration
syscall=getuid

no_threads=($(grep no_thread < param))
no_threads=${no_threads[@]:1}
sample_sizes=($(grep sample_size < param))
sample_sizes=${sample_sizes[@]:1}

echo "mean,std,no_thread,sample_size" > results/${prog_name}_${tracer_name}.csv
function save_stats {
    mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_thread,$sample_size" >> results/${prog_name}_${tracer_name}.csv
}

function clean {
	rm sample
	rm statistics
}

for no_thread in $no_threads; do
	for sample_size in $sample_sizes; do
		./$prog_name -s $sample_size -t $no_thread
		save_stats
		clean
	done
done
