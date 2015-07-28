#/bin/bash

cd $(dirname $0)
benchmark_path=$(pwd)

#<<COMMENT

./clean.sh

#calibrate
#if [ ! -d calibration ]; then mkdir calibration
#else rm calibration/*
#fi
#event_rates=$(grep "event rates" < param)
calibration_path=../../../scripts/calibrate/v2.0
cp calibration/calibrate.param $calibration_path/calibrate.param
cd $calibration_path
#echo $event_rates > calibrate.param
./calibrate.sh
cd $benchmark_path
mv $calibration_path/*.result calibration/
mv $calibration_path/*.pdf calibration/
mv $calibration_path/*.csv calibration/

#COMMENT

#benchmark lttng
lttng_path=../../../scripts/lttng/v6.0
#no_th=1
delays=""
while read line; do
	line=($line)
	delays="$delays ${line[3]}"
done < "calibration/calibrate_noth=1.result"
delay_line=$(grep delay < lttng/lttng.param)
sed -i "s/$delay_line/delay: $delays/" lttng/lttng.param
#no_th_line=$(grep no_thread < lttng/lttng.param)
#sed -i "s/$no_th_line/no_thread: $no_th/" lttng/lttng.param
cp lttng/lttng.param $lttng_path/lttng.param
cd $lttng_path
./lttng.sh
cd $benchmark_path
mv $lttng_path/getuid_pthread_lttng.csv lttng/

#COMMENT
#<<COMMENT

#Plot lost events figs with R
R_path=../../../R_analysis/lost_events/v4.1
cp lttng/getuid_pthread_lttng.csv $R_path/results
cd $R_path
#rm results/figs/*
Rscript lost_events.R
cd $benchmark_path
mv $R_path/results/figs/* lttng/figs/lost_events

#COMMENT
R_path=../../../R_analysis/overhead/v1.0
cp calibration/getuid_pthread_calibrate.csv $R_path/results
cp lttng/getuid_pthread_lttng.csv $R_path/results
cd $R_path
#rm results/figs/*
Rscript overhead.R
cd $benchmark_path
mv $R_path/results/figs/* lttng/figs/overhead

