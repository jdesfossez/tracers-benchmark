#include <assert.h>
#include <stdio.h>

#include "ts_util.h"

//t1 == t2?
bool ts_is_equal(ts_t *t1, ts_t *t2) {
	bool ret = 1;
	if (t1->tv_sec != t2->tv_sec) ret = 0;
	if (t1->tv_nsec != t2->tv_nsec) ret = 0;
	return ret;
}

//t1 < t2?
bool ts_is_less(ts_t *t1, ts_t *t2) {
    bool ret = 0;
    if (t1->tv_sec < t2->tv_sec) ret = 1;
    else if (t1->tv_sec == t2->tv_sec)
        if (t1->tv_nsec < t2->tv_nsec) ret = 1;
    return ret;
}

long ts_to_l(ts_t *t) {
    long ret = 1E9 * t->tv_sec + t->tv_nsec;
    return ret;
}

//t2-t1
ts_t ts_sub(ts_t *t1, ts_t *t2) {
	assert(ts_is_less(t1,t2));
	struct timespec ret;
	if (t1->tv_nsec >= t2->tv_nsec){
		t2->tv_sec--;
		t2->tv_nsec += 1E9;
	}
	ret.tv_nsec = t2->tv_nsec-t1->tv_nsec;
	ret.tv_sec = t2->tv_sec-t1->tv_sec;
	return ret;
}

void ts_printf(ts_t *t) {
	printf("%ld sec %ld nsec\n", t->tv_sec, t->tv_nsec);
}
