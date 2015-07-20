#include <stdio.h>

#include "ts_util.h"

int main(int argc, char *argv[]) {

	ts_t t1, t2, t3, t4;

	t1.tv_sec = 1;
	t1.tv_nsec = 50;
	t2.tv_sec = 1;
	t2.tv_nsec = 50;
	if (ts_is_equal(&t1, &t2)) printf("test is_equal_true: pass\n");
	else printf("test is_equal_true: fail\n");

	t1.tv_sec = 1;
	t1.tv_nsec = 50;
	t2.tv_sec = 2;
	t2.tv_nsec = 50;
	if (!ts_is_equal(&t1, &t2)) printf("test is_equal_sec_false: pass\n");
	else printf("test is_equal_sec_false: fail\n");

	t1.tv_sec = 1;
	t1.tv_nsec = 50;
	t2.tv_sec = 1;
	t2.tv_nsec = 60;
	if (!ts_is_equal(&t1, &t2)) printf("test is_equal_nsec_false: pass\n");
	else printf("test is_equal_nsec_false: fail\n");

	clock_gettime(CLOCK_MONOTONIC_RAW, &t1);
	clock_gettime(CLOCK_MONOTONIC_RAW, &t2);
	if (ts_is_less(&t1, &t2)) printf("test ts_is_less_true: pass\n");
	else printf("test ts_is_less_true: fail\n");

	clock_gettime(CLOCK_MONOTONIC_RAW, &t2);
	clock_gettime(CLOCK_MONOTONIC_RAW, &t1);
	if (!ts_is_less(&t1, &t2)) printf("test ts_is_less_false: pass\n");
	else printf("test ts_is_less_false: fail\n");

	t1.tv_sec = 1;
	t1.tv_nsec = 50;
	t2.tv_sec = 1;
	t2.tv_nsec = 60;
	t3.tv_sec = 0;
	t3.tv_nsec = 10;
	t4 = ts_sub(&t1, &t2);
	if (ts_is_equal(&t3, &t4)) printf("test ts_sub: pass\n");
	else printf("test ts_sub: fail\n");

	t1.tv_sec = 0;
	t1.tv_nsec = 50;
	t2.tv_sec = 1;
	t2.tv_nsec = 40;
	t3.tv_sec = 0;
	t3.tv_nsec = 1E9 - 10;
	t4 = ts_sub(&t1, &t2);
	if (ts_is_equal(&t3, &t4)) printf("test ts_sub_smaller_nsec: pass\n");
	else printf("test ts_sub_smaller_nsec: fail\n");

	t1.tv_sec = 1;
	t1.tv_nsec = 1;
	long l_ts = ts_to_l(&t1);
	if (l_ts == 1E9 + 1) printf("test ts_to_l: pass\n");
	else printf("test ts_to_l: fail\n");

	ts_printf(&t1);

	return 0;
}
