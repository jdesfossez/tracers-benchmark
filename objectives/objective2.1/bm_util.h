#ifndef BM_UTIL_H
#define BM_UTIL_H

#include "../objective1.2/ts_util.h"

void timestamps_to_intervals(ts_t *, ts_t *, long *, int);

double compute_mean(long *, int);
double compute_std(long *, int);

void save_intervals(long *, int);
void save_statistics(double, double);

#endif
