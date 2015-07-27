#!/bin/bash

function run
{
	./$prog_name -d $delay -s $sample_size -t $no_thread > /dev/null
	mean=($(grep mean < statistics)) 
	echo "${mean[1]},$delay,$no_thread" >> ${prog_name}_calibrate.csv
	rm sample
	rm statistics
}

cd $(dirname $0)
prog_name=getuid_pthread
syscall=getuid
no_cpus=$(nproc)
cpu_max=$(($no_cpus - 1))

change_cpus_governor_cmd=../../change_cpus_governor/v1.0/change_cpus_governor.sh
prog_path=../../../load/getuid_pthread/v2.0/
make -C $prog_path
mv $prog_path/getuid_pthread .

sample_size=100000
event_rates=($(grep "event rates" < calibrate.param))
event_rates=${event_rates[@]:3}
no_threads=""
no_thread=1
while [ $no_thread -le $no_cpus ]; do
	no_threads="$no_threads $no_thread"
	no_thread=$(($no_thread * 2))
done
delays="1 4 16 64 256 1024 4096 16384"

$change_cpus_governor_cmd performance

echo "mean,delay,no_th" > ${prog_name}_calibrate.csv
for no_thread in $no_threads; do
	for delay in $delays; do
		run
	done
done

target_delay=$(Rscript fit_delay.R $event_rates | tail -n1 | cut -d" " -f2)


echo "mean,delay,no_th" > ${prog_name}_calibrate.csv
for no_thread in $no_threads; do
	while read line; do
		line=($line)
		delay=${line[3]}
		run
	done < "calibrate_noth=1.result"
done

$change_cpus_governor_cmd powersave
rm $prog_name


