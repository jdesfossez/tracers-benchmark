#!/bin/bash -x

cd $(dirname $0)

make

prog_name=clock_gettime
tracer_name=system_tap
sample_size=$1

echo "mean,std,sample_size,probe_content" > ${prog_name}_${tracer_name}.csv
function save_stats {
    mean=($(grep mean < statistics))
	    std=($(grep std < statistics))
		    echo "${mean[1]},${std[1]},$sample_size,${probe_content[$i]}" >> ${prog_name}_${tracer_name}.csv
}

declare -a probe_sys_entry_content
declare -a probe_sys_exit_content
declare -a probe_content
probe_sys_entry_content[0]=" "
probe_sys_entry_content[1]='printf("syscall.clock_gettime.entry\n")'
probe_sys_entry_content[2]='printf("[%ld] syscall.clock_gettime.entry\n", gettimeofday_us())'
probe_sys_exit_content[0]=" "
probe_sys_exit_content[1]='printf("syscall.clock_gettime.exit\n")'
probe_sys_exit_content[2]='printf("[%ld] syscall.clock_gettime.exit\n", gettimeofday_us())'
probe_content[0]="empty probes"
probe_content[1]="print entry and exit to file"
probe_content[2]="print entry and exit to file with gettimeofday_us() timestamp"

for i in 0 1 2; do
	echo "probe syscall.clock_gettime {${probe_sys_entry_content[$i]}}" > ${prog_name}.stp
	echo "probe syscall.clock_gettime.return {${probe_sys_exit_content[$i]}}" >> ${prog_name}.stp
	stap -g --suppress-time-limits -v ${prog_name}.stp -c "./$prog_name -s $sample_size" > stap.out
	save_stats
done
