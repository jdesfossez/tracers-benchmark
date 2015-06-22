
#define _GNU_SOURCE
#include <sched.h>

#include <assert.h>
#include <getopt.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#include "../objective2.1/bm_util.h"

#define DEFAULT_SAMPLE_SIZE 100
#define DEFAULT_NO_THREADS 2
const char *const prog_name = "clock_gettime";

pthread_barrier_t barrier;

struct args_t {
	int sample_size;
	int no_threads;
};
struct args_t args = { DEFAULT_SAMPLE_SIZE, DEFAULT_NO_THREADS };

struct worker_args_t {
	int sample_size;
	int thread_no;
	ts_t *ts_ptr;
};

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: %s [OPTIONS] [COMMAND]\n", prog_name);
        fprintf(stderr, "Calls repeatedly the clock_gettime system call, saves the values to memory and prints them to stdout");
        fprintf(stderr, "\nOptions:\n\n");
        fprintf(stderr, "-s    Sample size\n");
		fprintf(stderr, "-t    Number of threads\n");
        fprintf(stderr, "-h    This help message\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv){
    int opt;
    while ((opt = getopt(argc, argv, "hs:t:")) != -1) {
        switch (opt) {
            case 's':
                args.sample_size = atoi(optarg);
                break;
			case 't':
				args.no_threads = atoi(optarg);
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

void *worker(void *worker_args_) {
	struct worker_args_t worker_args = *((struct worker_args_t*) worker_args_);
	ts_t *ts_iter = worker_args.ts_ptr;

    cpu_set_t mask;
    CPU_ZERO(&mask);
    CPU_SET(worker_args.thread_no, &mask);
    pthread_setaffinity_np(pthread_self(), sizeof(mask), &mask);

    /*pthread_getaffinity_np(pthread_self(), sizeof(mask), &mask);
    int j;
    for (j = 0; j < CPU_SETSIZE; j++) {
		if (CPU_ISSET(j, &mask))  printf("\tThread: %d\tCPU: %d\n", worker_args.thread_no, j);
	}*/

	pthread_barrier_wait(&barrier);
	for(ts_iter; ts_iter < worker_args.ts_ptr + worker_args.sample_size + 1; ts_iter++){
		clock_gettime(CLOCK_MONOTONIC_RAW, ts_iter);
	}
}

int main(int argc, char *argv[]){
	parse_args(argc, argv);
	int sample_size = args.sample_size;
	int no_threads = args.no_threads;
	int sample_size_per_thread = sample_size / no_threads;
	assert(sample_size > 0);
	assert(no_threads > 0);
	assert(sample_size == sample_size_per_thread * no_threads);

	ts_t *timestamps = calloc(sample_size + no_threads, sizeof(ts_t));
	pthread_t *threads = calloc(no_threads, sizeof(pthread_t));
	int thread_no;
	struct worker_args_t *worker_args = calloc(no_threads, sizeof(struct worker_args_t));

	pthread_barrier_init(&barrier, NULL, no_threads);
	for (thread_no = 0; thread_no < no_threads; thread_no++) {
		worker_args[thread_no] = (struct worker_args_t) { sample_size_per_thread, thread_no, timestamps + (sample_size_per_thread + 1 ) * thread_no};
		pthread_create(&threads[thread_no], NULL, worker, (void *) &worker_args[thread_no]);
	}
	for (thread_no = 0; thread_no < no_threads; thread_no++) {
		pthread_join(threads[thread_no], NULL);
	}
	pthread_barrier_destroy(&barrier);

	long *dt = calloc(sample_size, sizeof(long));
	ts_t *ts_ptr;
	long* dt_ptr;
	for (thread_no = 0; thread_no < no_threads; thread_no++) {
		ts_ptr = timestamps + thread_no * (sample_size_per_thread + 1);
		dt_ptr = dt + thread_no * sample_size_per_thread;
		timestamps_to_intervals(ts_ptr, ts_ptr + 1, dt_ptr, sample_size_per_thread);
	}

	save_intervals(dt, sample_size);
	double mean = compute_mean(dt, sample_size);
	double std = compute_std(dt, sample_size);
	save_statistics(mean, std);

	free(dt);
	free(threads);
	free(timestamps);
	free(worker_args);

	return 0;
}
