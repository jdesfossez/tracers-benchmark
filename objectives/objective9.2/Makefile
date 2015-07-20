CFLAGS=-lm -pthread
PROG_NAME=getuid_pthread
SRC=utils/ts_util.c utils/bm_util.c $(PROG_NAME).c

all:
	gcc -o $(PROG_NAME) $(SRC) $(CFLAGS)

clean:
	rm -r results
