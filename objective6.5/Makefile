CFLAGS=-lm -pthread
PROG_NAME=clock_gettime_pthread
TRACER_NAME=ftrace
SRC=../objective1.2/ts_util.c ../objective2.1/bm_util.c $(PROG_NAME).c

all:
	gcc -o $(PROG_NAME) $(SRC) $(CFLAGS)

clean:
	rm $(PROG_NAME)
	rm $(PROG_NAME)_$(TRACER_NAME).csv
	sudo rm $(PROG_NAME).out
	sudo rm sample
	sudo rm statistics
	sudo rm trace.dat
