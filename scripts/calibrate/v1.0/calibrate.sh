#!/bin/bash

cd $(dirname $0)
prog_name=getuid_pthread
syscall=getuid
no_cpus=$(nproc)
cpu_max=$(($no_cpus - 1))

change_cpus_governor_cmd=../../change_cpus_governor/v1.0/change_cpus_governor.sh
prog_path=../../../load/getuid_pthread/v2.0/
make -C $prog_path
mv $prog_path/getuid_pthread .

event_rate=$(grep "event rate" < calibrate.param | cut -d" " -f4)
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
		./$prog_name -d $delay -s 100000 -t $no_thread > /dev/null
		mean=($(grep mean < statistics)) 
		echo "${mean[1]},$delay,$no_thread" >> ${prog_name}_calibrate.csv
		rm sample
		rm statistics
	done
done

$change_cpus_governor_cmd powersave
rm $prog_name


target_delay=$(Rscript fit_delay.R $event_rate | tail -n1 | cut -d" " -f2)
