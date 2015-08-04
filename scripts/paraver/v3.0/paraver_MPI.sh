#!/bin/bash

function load_params {
	heights=($(grep "height:" < ${output_file}.param))
	heights=${heights[@]:1}
	widths=($(grep "width:" < ${output_file}.param))
	widths=${widths[@]:1}
	sample_sizes=($(grep "sample size:" < ${output_file}.param))
	sample_sizes=${sample_sizes[@]:2}
}

function clean {
	rm time.out
	rm -f TRACE.*
	rm -rf set-0
	rm -f *.pcf
	rm -f *.prv
	rm -f *.row
}

function run {
	echo $output_file
	echo "time,height,width,num_procs,sample_size,num_MPI_msgs" > ${output_file}.csv
	for height in $heights; do
		for width in $widths; do
			for sample_size in $sample_sizes; do
				area=$((height * width))
				num_MPI_msgs=$((2 * 4 * $area * $sample_size))
				cmd="mpirun -np $area ./$prog_name -h $height -w $width -s $sample_size"
				echo $cmd
				(time $cmd) &> time.out
				minutes=$(grep "real" < time.out | cut -f2 | cut -d'm' -f1)
				seconds=$(grep "real" < time.out | cut -f2 | cut -d'm' -f2 | cut -d's' -f1)
				time=$(echo "60 * $minutes + $seconds" | bc)
				echo "$time,$height,$width,$area,$sample_size,$num_MPI_msgs" >> ${output_file}.csv
				clean
			done
		done
	done
}

prog_name=MPI_2Dexchange
load_path=../../../load/MPI_2Dexchange/v2.0
make -C $load_path
mv $load_path/$prog_name .
#warmup
mpirun -np 4 ./$prog_name -h 2 -w 2 -s 10
#no tracing
output_file="paraver_MPI.calibration"
load_params
run

export EXTRAE_HOME=/home/gdc/opt/extrae
export EXTRAE_CONFIG_FILE=extrae.xml
export LD_PRELOAD=${EXTRAE_HOME}/lib/libmpitrace.so # For C apps
#export LD_PRELOAD=${EXTRAE_HOME}/lib/libmpitracef.so # For Fortran apps
output_file="paraver_MPI.ld_preload"
load_params
run

rm MPI_2Dexchange
