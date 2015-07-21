#!/bin/bash -x

function set_lttng_delay {
	delay_line=$(grep delay < scan.param)
	sed -i "s/$delay_line/delay: $delay/" scan.param
	cp scan.param $lttng_path/lttng.param
}

function set_lttng_sample_size {
	sample_size_line=$(grep sample_size < scan.param)
	sed -i "s/$sample_size_line/sample_size: $sample_size/" scan.param
	cp scan.param $lttng_path/lttng.param
}

function run_lttng {
	./$lttng_path/lttng.sh
	frac_lost_events=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f3)
}

cd $(dirname $0)
lttng_path=../../lttng/v5.2

total_buf_size=$(grep total_buf_size < scan.param | cut -d' ' -f2)
sample_size=$(grep sample_size < scan.param | cut -d' ' -f2)

trace_size=0
frac_lost_events=0
delay=1
set_lttng_delay
while (( $(bc <<< "(1 - $frac_lost_events) * 10 * $total_buf_size > $trace_size") == 1 ));do
	set_lttng_sample_size
	run_lttng
	trace_size=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f5)
	sample_size=$(($sample_size * 2))
done
sample_size=$(($sample_size / 2))

frac_lost_events=1
if (( $(bc <<< "$frac_lost_events > 0") == 1 )); then
	while (( $(bc <<< "$frac_lost_events > 0") == 1 )); do
		delay=$(($delay * 10))
		set_lttng_delay
		run_lttng
	done

	frac_lost_events=1
	delay=$(($delay / 10))
	delta=$delay
	while (( $(bc <<< "$frac_lost_events > 0") == 1 )); do
		delay=$(($delay + $delta))
		set_lttng_delay
		run_lttng
	done
fi

sdf=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f4)
trace_size=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f5)
sdt=$(sed -n '2p' $lttng_path/getuid_pthread_lttng.csv | cut -d',' -f6)
echo "delay: $delay iterations" > scanned.param
echo "sample size: $sample_size" >> scanned.param
echo "fraction of lost events: $frac_lost_events +- $sdf," >> scanned.param
echo "trace size: $trace_size Kb +- $sdt" >> scanned.param
rm $lttng_path/getuid_pthread_lttng.csv
