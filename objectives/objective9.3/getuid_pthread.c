
#define _GNU_SOURCE
#include <sched.h>

#include <assert.h>
#include <getopt.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "../objective2.1/bm_util.h"

#define DEFAULT_SAMPLE_SIZE 100
#define DEFAULT_NO_THREADS 2
#define BURST_SIZE 8192
const char *const prog_name = "clock_gettime";

pthread_barrier_t barrier;

struct args_t {
	int sample_size;
	int no_threads;
	int no_cpus;
};
struct args_t args = { DEFAULT_SAMPLE_SIZE, DEFAULT_NO_THREADS, 0 };

struct worker_args_t {
	int sample_size;
	int thread_no;
	int cpu_affinity;
	ts_t *ts_ptr;
};

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: %s [OPTIONS] [COMMAND]\n", prog_name);
        fprintf(stderr, "Calls repeatedly the clock_gettime system call, saves the values to memory and prints them to stdout");
        fprintf(stderr, "\nOptions:\n\n");
        fprintf(stderr, "-n    Number of cpus available\n");
		fprintf(stderr, "-s    Sample size\n");
		fprintf(stderr, "-t    Number of threads\n");
        fprintf(stderr, "-h    This help message\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv){
    int opt;
	while ((opt = getopt(argc, argv, "hn:s:t:")) != -1) {
        switch (opt) {
			case 'n':
				args.no_cpus = atoi(optarg);
				break;
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

void randomize_cpu_affinities(int *cpu_affinities) {
	int i, j, rank;
	int no_cpus_available = args.no_cpus;
	int *cpus_available = calloc(args.no_cpus, sizeof(int));
	for(i = 0; i < args.no_cpus; i++) cpus_available[i] = i;
	for(i = 0; i < args.no_cpus; i++) {
		rank = rand() % no_cpus_available;
		cpu_affinities[i] = cpus_available[rank];
		no_cpus_available--;
		for(j = rank; j < no_cpus_available; j++) cpus_available[j] = cpus_available[j+1];
	}
	free(cpus_available);
}

void *worker(void *worker_args_) {
	struct worker_args_t worker_args = *((struct worker_args_t*) worker_args_);
	ts_t *ts_iter = worker_args.ts_ptr;

	cpu_set_t mask;
	CPU_ZERO(&mask);
	CPU_SET(worker_args.cpu_affinity, &mask);
	pthread_setaffinity_np(pthread_self(), sizeof(mask), &mask);

	int i=0;
	getuid();
	pthread_barrier_wait(&barrier);
	for(ts_iter, i; i < BURST_SIZE; ts_iter++, i++){
		clock_gettime(CLOCK_MONOTONIC_RAW, ts_iter);
		getuid();
	}
	clock_gettime(CLOCK_MONOTONIC_RAW, ts_iter);
}

int main(int argc, char *argv[]){
	parse_args(argc, argv);
	int sample_size = args.sample_size;
	int no_threads = args.no_threads;
	int no_cpus = args.no_cpus;
	int sample_size_per_thread = sample_size / no_threads;
	int no_bursts_per_thread = sample_size_per_thread / BURST_SIZE;
	assert(sample_size > 0);
	assert(no_threads > 0);
	assert(sample_size == sample_size_per_thread * no_threads);
	assert(sample_size_per_thread == no_bursts_per_thread * BURST_SIZE);
	srand(time(NULL));

	ts_t *timestamps = calloc(sample_size + no_bursts_per_thread * no_threads, sizeof(ts_t));
	pthread_t *threads = calloc(no_threads, sizeof(pthread_t));
	struct worker_args_t *worker_args = calloc(no_threads, sizeof(struct worker_args_t));
	int *cpu_affinities = calloc(no_cpus, sizeof(int));
	pthread_barrier_init(&barrier, NULL, no_threads);
	int burst, thread_no;
	for (burst = 0; burst < no_bursts_per_thread; burst++) {
		randomize_cpu_affinities(cpu_affinities);
		for (thread_no = 0; thread_no < no_threads; thread_no++) {
			worker_args[thread_no] = (struct worker_args_t) { BURST_SIZE, thread_no, cpu_affinities[thread_no], timestamps + thread_no * (sample_size_per_thread + no_bursts_per_thread ) +  burst * (BURST_SIZE + 1 )};
			pthread_create(&threads[thread_no], NULL, worker, (void *) &worker_args[thread_no]);
		}
		for (thread_no = 0; thread_no < no_threads; thread_no++) {
			pthread_join(threads[thread_no], NULL);
		}
	}
	pthread_barrier_destroy(&barrier);

	long *dt = calloc(sample_size, sizeof(long));
	ts_t *ts_ptr;
	long* dt_ptr;

	for (burst = 0; burst < no_bursts_per_thread; burst++){
		for (thread_no = 0; thread_no < no_threads; thread_no++) {
			ts_ptr = timestamps + thread_no * (sample_size_per_thread + no_bursts_per_thread) + burst * (BURST_SIZE + 1);
			dt_ptr = dt + thread_no * sample_size_per_thread + burst * BURST_SIZE;
			timestamps_to_intervals(ts_ptr, ts_ptr + 1, dt_ptr, BURST_SIZE);
		}
	}

	save_intervals(dt, sample_size);
	double mean = compute_mean(dt, sample_size);
	double std = compute_std(dt, sample_size);
	save_statistics(mean, std);

	free(cpu_affinities);
	free(dt);
	free(threads);
	free(timestamps);
	free(worker_args);

	return 0;
}
