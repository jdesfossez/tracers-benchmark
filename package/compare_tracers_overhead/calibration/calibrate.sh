#!/bin/bash

function load_params {
	event_rates=($(grep "event rates" < calibrate.param))
	event_rates=${event_rates[@]:3}
	sample_size=($(grep "sample size:" < calibrate.param))
	sample_size=${sample_size[@]:2}
	no_threads=($(grep "no threads:" < calibrate.param))
	no_threads=${no_threads[@]:2}
}

function run
{
	cmd="./$load_name -d $delay -s $sample_size -t $no_thread" > /dev/null
	echo $cmd
	$cmd > /dev/null
	mean=($(grep mean < statistics)) 
	echo "mean: ${mean[1]}, delay: $delay, no_thread: $no_thread"
	echo "${mean[1]},$delay,$no_thread" >> ${load_name}_calibrate.csv
	rm sample
	rm statistics
}

cd $(dirname $0)
if [ "$1" == "clean" ]; then
	rm *.pdf
	rm *.csv
	rm *.result
	exit
fi

no_cpus=$(nproc)
load_name=getuid_pthread
load_params
delays="1 4 16 64 256 1024 4096 16384"
if [ ! -f "../load/$load_name" ]; then make -C ../load; fi
cp ../load/$load_name .


../scripts/change_cpus_governor.sh performance

echo "mean,delay,no_th" > ${load_name}_calibrate.csv
for no_thread in $no_threads; do
	for delay in $delays; do
		run
	done
done

Rscript fit_delay.R $event_rates > /dev/null

echo "mean,delay,no_th" > ${load_name}_calibrate.csv
for no_thread in $no_threads; do
	while read line; do
		line=($line)
		delay=${line[3]}
		run
	done < "calibrate_noth=${no_thread}.result"
done

../scripts/change_cpus_governor.sh powersave
rm $load_name


