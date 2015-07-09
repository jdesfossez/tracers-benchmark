#include <math.h>
#include <stdio.h>

#include "bm_util.h"

double compute_mean(long *dt, int size) {
	double mean = 0;
	long *dt_ptr = dt;
	for (dt_ptr; dt_ptr < dt + size; dt_ptr++) {
		mean += (double) *dt_ptr / (double) size;
	}
	return mean;
}

//unbiased estimator using size - 1 instead of size
double compute_std(long *dt, int size) {
	double delta, mean, std, var = 0;
	long *dt_ptr = dt;
	mean = compute_mean(dt, size);
	for (dt_ptr; dt_ptr < dt + size; dt_ptr++) {
		delta = (mean - (double) *dt_ptr);
		var += delta * delta / (double) (size - 1);
	}
	std = sqrt(var);
	return std;
}

void save_intervals(long *dt, int size) {
	FILE *output;
	long *dt_ptr = dt;
	output = fopen("sample", "w");
	for (dt_ptr; dt_ptr < dt + size; dt_ptr++) {
		fprintf(output, "%ld\n", *dt_ptr);
	}
	fclose(output);
}

void save_statistics(double mean, double std) {
	FILE *output;
	output = fopen("statistics", "w");
	fprintf(output, "mean: %.5g\n std: %.5g", mean, std);
	fclose(output);
}

void timestamps_to_intervals(ts_t *ti, ts_t *tf, long *dt, int size) {
	ts_t *ti_ptr = ti;
	ts_t *tf_ptr = tf;
	long *dt_ptr = dt;
	int i;
	ts_t interval;
	for (i =0; i < size; i++, ti_ptr++, tf_ptr++, dt_ptr++) {
		interval = ts_sub(ti_ptr, tf_ptr);
		*dt_ptr = ts_to_l(&interval);
	}
}
