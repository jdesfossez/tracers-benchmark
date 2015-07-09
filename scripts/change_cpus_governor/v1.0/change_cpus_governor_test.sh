#!/bin/bash

function change_governors {
	./change_cpus_governor.sh $scaling_governor
	for i in $(seq 0 $cpu_max); do
		read sg < /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
		echo "scaling_governor $i: $sg"
	done
}

let cpu_max=$(nproc)-1

for scaling_governor in performance powersave unknown; do
	change_governors
done
