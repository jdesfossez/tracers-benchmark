#ifndef TS_UTIL_H 
#define TS_UTIL_H

#include <stdbool.h>
#include <time.h>

typedef struct timespec ts_t;

bool ts_is_equal(ts_t *, ts_t *);
bool ts_is_less(ts_t *, ts_t *);

ts_t ts_sub(ts_t *, ts_t *);

long ts_to_l(ts_t *);

void ts_printf(ts_t *);

#endif

