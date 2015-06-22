CFLAGS=-lm
SRC=../objective1.2/ts_util.c ../objective2.1/bm_util.c clock_gettime.c

all:
	gcc -o clock_gettime $(SRC) $(CFLAGS)

clean:
	rm clock_gettime
	sudo rm clock_gettime.out
	sudo rm sample
	sudo rm statistics
	sudo rm perf.data*
