CFLAGS=-lm -pthread
PROG_NAME=getuid_pthread
SRC=../objective1.2/ts_util.c ../objective2.1/bm_util.c $(PROG_NAME).c

all:
	gcc -o $(PROG_NAME) $(SRC) $(CFLAGS)

clean:
	rm $(PROG_NAME)
	rm sample
	rm statistics
