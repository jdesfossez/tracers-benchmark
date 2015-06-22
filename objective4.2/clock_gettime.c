
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

#include "../objective2.1/bm_util.h"

#define DEFAULT_NO_REPS 100
const char *const prog_name = "clock_gettime";

struct args_t {
	int no_reps;
};
struct args_t args = { DEFAULT_NO_REPS };

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: %s [OPTIONS] [COMMAND]\n", prog_name);
        fprintf(stderr, "Calls repeatedly the clock_gettime system call, saves the values to memory and prints them to stdout");
        fprintf(stderr, "\nOptions:\n\n");
        fprintf(stderr, "-s    Number of repetitions\n");
        fprintf(stderr, "-h    This help message\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv){
    int opt;
    while ((opt = getopt(argc, argv, "hs:")) != -1) {
        switch (opt) {
            case 's':
                args.no_reps = atol(optarg);
                break;
            case 'h':
                usage();
                break;
            default:
                usage();
                break;
        }
    }
}

int main(int argc, char *argv[]){
	parse_args(argc, argv);
	int no_reps = args.no_reps;

	ts_t *timestamps = calloc(no_reps, sizeof(ts_t));
	ts_t *ts_ptr = timestamps;

	int i;
	for(ts_ptr = timestamps; ts_ptr < timestamps + no_reps; ts_ptr++){
		clock_gettime(CLOCK_MONOTONIC_RAW, ts_ptr);
	}

	int size = no_reps - 1;
	long *dt = calloc(size, sizeof(long));
	timestamps_to_intervals(timestamps, timestamps + 1, dt, size);

	save_intervals(dt, size);
	double mean = compute_mean(dt, size);
	double std = compute_std(dt, size);
	save_statistics(mean, std);

	return 0;
}
