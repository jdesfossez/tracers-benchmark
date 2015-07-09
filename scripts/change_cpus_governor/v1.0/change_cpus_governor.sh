#!/bin/bash

let cpu_max=$(nproc)-1
scaling_governor=$1
if [ $scaling_governor != "performance" ] && [ $scaling_governor != "powersave" ]; then
	echo "WARNING: scaling governor \"$scaling_governor\" is neither performance nor powersave."
fi

for i in $(seq 0 $cpu_max); do
	if [ -f /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor ]; then
		sudo bash -c "echo $scaling_governor > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
	fi
done
