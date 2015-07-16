#!/bin/bash -x

cd $(dirname $0)


lttng_path=../../lttng/v5.2

frac_lost_events=1
delay=1
while (( $(bc <<< "$frac_lost_events > 0") == 1 )); do
	delay=$(($delay * 10))
	delay_line=$(grep delay < lttng.param)
	sed -i "s/$delay_line/delay: $delay/" lttng.param
	cp lttng.param $lttng_path
	./$lttng_path/lttng.sh
	frac_lost_events=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f3)
	sd=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f4)
done

frac_lost_events=1
delay=$(($delay / 10))
delta=$delay
while (( $(bc <<< "$frac_lost_events > 0") == 1 )); do
	delay=$(($delay + $delta))
	delay_line=$(grep delay < lttng.param)
	sed -i "s/$delay_line/delay: $delay/" lttng.param
	cp lttng.param $lttng_path
	./$lttng_path/lttng.sh
	frac_lost_events=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f3)
	sd=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f4)
done

echo -e "delay: $delay iterations,\nfraction of lost events: $frac_lost_events+-$sd"
rm $lttng_path/getuid_pthread_lttng.csv
