CFLAGS=-lm -pthread
PROG_NAME=clock_gettime_pthread
TRACER_NAME=lttng
SRC=../objective1.2/ts_util.c ../objective2.1/bm_util.c $(PROG_NAME).c

all:
	gcc -o $(PROG_NAME) $(SRC) $(CFLAGS)

clean:
	rm $(PROG_NAME)
	rm $(PROG_NAME)_$(TRACER_NAME).csv
	rm sample
	rm statistics
	rm -r traces
