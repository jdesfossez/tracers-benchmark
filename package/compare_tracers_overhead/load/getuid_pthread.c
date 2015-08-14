
#define _GNU_SOURCE
#include <sched.h>

#include <assert.h>
#include <getopt.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#include "bm_util.h"

#define DEFAULT_AFFINITY 0
#define DEFAULT_DELAY 0
#define DEFAULT_SAMPLE_SIZE 100
#define DEFAULT_NO_THREADS 2
const char *const prog_name = "getuid_pthread";

pthread_barrier_t barrier;

struct args_t {
	int affinity;
	int delay;
	int sample_size;
	int no_threads;
};

struct worker_args_t {
	int affinity;
	int delay;
	int sample_size;
	int thread_no;
	ts_t *ts_ptr;
};

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: %s [OPTIONS] [COMMAND]\n", prog_name);
        fprintf(stderr, "Program that repeatedly calls clock_gettime and getuid syscalls and stores the measured timestamps in memory. Timestamps are converted to intervals and the mean and std of the sample are computed. The sample, its mean and std are saved to file. The program is running on multiple threads (pthread).");
        fprintf(stderr, "\nOptions:\n\n");
		fprintf(stderr, "-a    Set affinities\n");
		fprintf(stderr, "-d    Delay (Number of iterations)\n");
        fprintf(stderr, "-s    Sample size\n");
		fprintf(stderr, "-t    Number of threads\n");
        fprintf(stderr, "-h    This help message\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv, struct args_t *args){
    int opt;
	args->affinity = 0;
    while ((opt = getopt(argc, argv, "ahd:s:t:")) != -1) {
        switch (opt) {
			case 'a':
				args->affinity = 1;
				break;
			case 'd':
				args->delay = atoi(optarg);
				break;
            case 's':
                args->sample_size = atoi(optarg);
                break;
			case 't':
				args->no_threads = atoi(optarg);
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
	volatile int x;
	//set affinities
	if (worker_args.affinity) {
		cpu_set_t mask;
		CPU_ZERO(&mask);
		CPU_SET(worker_args.thread_no, &mask);
		pthread_setaffinity_np(pthread_self(), sizeof(mask), &mask);
	}
	//synchronize all threads
	pthread_barrier_wait(&barrier);
	//warm-up
	getuid();
	//perform benchmark
	for(ts_iter; ts_iter < worker_args.ts_ptr + worker_args.sample_size; ts_iter++){
		clock_gettime(CLOCK_MONOTONIC_RAW, ts_iter);
		getuid();
		x = 0;
		while(x < worker_args.delay) x++;
	}
	clock_gettime(CLOCK_MONOTONIC_RAW, ts_iter);
}

int main(int argc, char *argv[]){
	int sample_size_per_thread, thread_no;
	long *dt;
	long* dt_ptr;
	pthread_t *threads;
	struct args_t args = { DEFAULT_AFFINITY, DEFAULT_DELAY, DEFAULT_SAMPLE_SIZE, DEFAULT_NO_THREADS };
	struct worker_args_t *worker_args;
	ts_t *timestamps;
	ts_t *ts_ptr;

	//parse arguments
	parse_args(argc, argv, &args);

	//check arguments consistency
	sample_size_per_thread = args.sample_size / args.no_threads;
	assert(args.sample_size > 0);
	assert(args.no_threads > 0);
	assert(args.sample_size == sample_size_per_thread * args.no_threads);

	//output pid for trace analysis
	printf("pid: %d\n", getpid());

	//allocate and assign threads related variables
	threads = calloc(args.no_threads, sizeof(pthread_t));
	timestamps = calloc(args.sample_size + args.no_threads, sizeof(ts_t));
	worker_args = calloc(args.no_threads, sizeof(struct worker_args_t));
	//launch threads
	pthread_barrier_init(&barrier, NULL, args.no_threads);
	for (thread_no = 0; thread_no < args.no_threads; thread_no++) {
		worker_args[thread_no] = (struct worker_args_t) { args.affinity, args.delay, sample_size_per_thread, thread_no, timestamps + (sample_size_per_thread + 1 ) * thread_no};
		pthread_create(&threads[thread_no], NULL, worker, (void *) &worker_args[thread_no]);
	}
	//join threads
	for (thread_no = 0; thread_no < args.no_threads; thread_no++) {
		pthread_join(threads[thread_no], NULL);
	}
	pthread_barrier_destroy(&barrier);

	//convert timestamps to intervals
	dt = calloc(args.sample_size, sizeof(long));
	for (thread_no = 0; thread_no < args.no_threads; thread_no++) {
		ts_ptr = timestamps + thread_no * (sample_size_per_thread + 1);
		dt_ptr = dt + thread_no * sample_size_per_thread;
		timestamps_to_intervals(ts_ptr, ts_ptr + 1, dt_ptr, sample_size_per_thread);
	}
	//compute stats and save results
	save_intervals(dt, args.sample_size);
	double mean = compute_mean(dt, args.sample_size);
	double std = compute_std(dt, args.sample_size);
	save_statistics(mean, std);

	free(dt);
	free(threads);
	free(timestamps);
	free(worker_args);

	return 0;
}
