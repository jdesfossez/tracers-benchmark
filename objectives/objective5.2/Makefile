CFLAGS=-lm
SRC=../objective1.2/ts_util.c ../objective2.1/bm_util.c clock_gettime.c

all:
	gcc -o clock_gettime $(SRC) $(CFLAGS)

clean:
	rm clock_gettime
	rm clock_gettime_lttng_snapshot.csv
	rm sample
	rm statistics
