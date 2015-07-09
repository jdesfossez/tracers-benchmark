CFLAGS=-lm -pthread
PROG_NAME=getuid_pthread
SRC=../../ts_util/v1.0/ts_util.c ../../bm_util/v1.0/bm_util.c $(PROG_NAME).c

all:
	gcc -o $(PROG_NAME) $(SRC) $(CFLAGS)

clean:
	if [ -f $(PROG_NAME) ]; then rm $(PROG_NAME); fi
	if [ -f sample ]; then rm sample; fi
	if [ -f statistics ]; then rm statistics; fi
