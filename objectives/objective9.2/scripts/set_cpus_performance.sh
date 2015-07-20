#!/bin/bash -x

let cpu_max=$(nproc)-1
scaling_governor=$1

for i in $(seq 0 $cpu_max); do
	if [ -f /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor ]; then
		sudo bash -c "echo $scaling_governor > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
	fi
done
