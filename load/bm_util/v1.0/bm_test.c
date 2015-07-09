#include <stdio.h>

#include "bm_util.h"

#define SIZE 1000

int main(int argc, char *argv[]) {
	int i;
	long dt[SIZE];
	ts_t ti[SIZE], tf[SIZE];
	ts_t *ti_ptr, *tf_ptr;
	//Assign fake timestamps
	for (i = 1, ti_ptr = ti, tf_ptr = tf; i < (SIZE + 1); i++, ti_ptr++, tf_ptr++) {
		*ti_ptr = (ts_t) { i, i * 1E5 };
		*tf_ptr = (ts_t) { 2 * i, 2 * i * 1E5 };
	}
	//convert to intervals and save to file
	timestamps_to_intervals(ti, tf, dt, SIZE);
	save_intervals(dt, SIZE);
	//Reassign fake timestamps
	for (i = 1, ti_ptr = ti, tf_ptr = tf; i < (SIZE + 1); i++, ti_ptr++, tf_ptr++) {
		*ti_ptr = (ts_t) { 0, i };
		*tf_ptr = (ts_t) { 0, 2 * i };
	}
	timestamps_to_intervals(ti, tf, dt, SIZE);
	//Compute and save mean and std: expected 500.5 and 288.8194 (see bm_test.R)
	double mean = compute_mean(dt, SIZE);
	double std = compute_std(dt, SIZE);
	save_statistics(mean, std);
	printf("mean: %lf, std: %lf\n", mean, std);
	return 0;
}
