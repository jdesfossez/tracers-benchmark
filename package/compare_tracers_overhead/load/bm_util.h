#ifndef BM_UTIL_H
#define BM_UTIL_H

#include "ts_util.h"

double compute_mean(long *, int);
double compute_std(long *, int);
void save_intervals(long *, int);
void save_statistics(double, double);
void timestamps_to_intervals(ts_t *, ts_t *, long *, int);

#endif
