#!/bin/bash -x

cd ../$(dirname $0)

prog_name=getuid_pthread
tracer_name=system_tap
syscall=getuid

no_threads=($(grep no_thread < param))
no_threads=${no_threads[@]:1}
sample_sizes=($(grep sample_size < param))
sample_sizes=${sample_sizes[@]:1}

echo "mean,std,no_lost_events,no_thread,sample_size,probe_content" > results/${prog_name}_${tracer_name}.csv
function save_stats {
    mean=($(grep mean < statistics))
	    std=($(grep std < statistics))
		    echo "${mean[1]},${std[1]},$no_lost_events,$no_thread,$sample_size,${probe_content[$i]}" >> results/${prog_name}_${tracer_name}.csv
}

function clean {
	rm sample
	rm statistics
	rm stap.out
}

declare -a probe_sys_entry_content
declare -a probe_sys_exit_content
declare -a probe_content
probe_sys_entry_content[0]=" "
probe_sys_entry_content[1]="printf(\"syscall.${syscall}.entry\n\")"
probe_sys_entry_content[2]="printf(\"[%ld] syscall.${syscall}.entry\n\", gettimeofday_us())"
probe_sys_exit_content[0]=" "
probe_sys_exit_content[1]="printf(\"syscall.${syscall}.exit\n\")"
probe_sys_exit_content[2]="printf(\"[%ld] syscall.${syscall}.exit\n\", gettimeofday_us())"
probe_content[0]="empty probes"
probe_content[1]="print entry and exit to file"
probe_content[2]="print entry and exit to file with gettimeofday_us() timestamp"

for i in 0 1 2; do
	echo "probe syscall.$syscall {${probe_sys_entry_content[$i]}}" > ${prog_name}.stp
	echo "probe syscall.$syscall.return {${probe_sys_exit_content[$i]}}" >> ${prog_name}.stp
	for no_thread in $no_threads; do
		for sample_size in $sample_sizes; do
			stap -g --suppress-time-limits -v ${prog_name}.stp -c "./$prog_name -s $sample_size -t $no_thread" > stap.out
			if [ "${probe_content[$i]}" = "empty probes"  ]; then
				no_lost_events="NA"
			else
				no_events=$(wc -l < stap.out)
				no_lost_events=$((2 * $sample_size + 2 * $no_thread - $no_events))
			fi
			save_stats
			clean
		done
	done
done

rm ${prog_name}.stp
