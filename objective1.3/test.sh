#!/bin/bash

let cpu_max=$(nproc)-1

scaling_governor=performance
./set_cpus_performance.sh $scaling_governor
for i in $(seq 0 $cpu_max); do
	read sg < /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
	echo $sg
done

scaling_governor=powersave
./set_cpus_performance.sh $scaling_governor
for i in $(seq 0 $cpu_max); do
	read sg < /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
	echo $sg
done
