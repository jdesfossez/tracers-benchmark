#include <stdio.h>

#include "bm_util.h"

#define SIZE 1000

int main(int argc, char *argv[]) {
	ts_t ti[SIZE], tf[SIZE];
	ts_t *ti_ptr, *tf_ptr;
	int i;

	for (i = 1, ti_ptr = ti, tf_ptr = tf; i < (SIZE + 1); i++, ti_ptr++, tf_ptr++) {
		*ti_ptr = (ts_t) { i, i * 1E5 };
		*tf_ptr = (ts_t) { 2 * i, 2 * i * 1E5 };
	}
	long dt[SIZE];
	timestamps_to_intervals(ti, tf, dt, SIZE);
	save_intervals(dt, SIZE);

	for (i = 1, ti_ptr = ti, tf_ptr = tf; i < (SIZE + 1); i++, ti_ptr++, tf_ptr++) {
		*ti_ptr = (ts_t) { 0, i };
		*tf_ptr = (ts_t) { 0, 2 * i };
	}
	timestamps_to_intervals(ti, tf, dt, SIZE);
	double mean = compute_mean(dt, SIZE);
	double std = compute_std(dt, SIZE);
	printf("mean: %lf, std: %lf\n", mean, std);
	save_statistics(mean, std);
	return 0;
}
