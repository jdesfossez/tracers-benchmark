#!/bin/bash -x

cd ../$(dirname $0)

if [ ! -d results ]; then
    mkdir results
fi

if [ ! -f getuid_pthread ];then
	make
fi

prog_name=getuid_pthread
tracer_name=ftrace
syscall=getuid

no_threads=($(grep no_thread < param))
no_threads=${no_threads[@]:1}
sample_sizes=($(grep sample_size < param))
sample_sizes=${sample_sizes[@]:1}

echo "mean,std,no_lost_events,no_thread,sample_size" > results/${prog_name}_${tracer_name}.csv
function save_stats {
    mean=($(grep mean < statistics))
	std=($(grep std < statistics))
	echo "${mean[1]},${std[1]},$no_lost_events,$no_thread,$sample_size" >> results/${prog_name}_${tracer_name}.csv
}

function clean {
    sudo rm sample
    sudo rm statistics
    sudo rm trace.dat
    sudo rm ${prog_name}.out
}

for no_thread in $no_threads; do
	for sample_size in $sample_sizes; do
		cmd="./$prog_name -s $sample_size -t $no_thread"
		sudo trace-cmd record -e "syscalls:sys_enter_${syscall}" -e "syscalls:sys_exit_${syscall}" $cmd > ${prog_name}.out
		no_events=$(trace-cmd report | grep $syscall | wc -l)
		no_lost_events=$((2 * $sample_size + 2 * $no_thread - $no_events))
		save_stats
		clean
	done
done

