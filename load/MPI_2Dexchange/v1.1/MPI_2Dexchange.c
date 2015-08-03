#include <assert.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

struct args_t {
    int lin_size;
    int sample_size;
	int verbose;
};

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: MPI_2Dexchange [OPTIONS] [COMMAND]\n");
        fprintf(stderr, "Program that creates a 2D square lattice of linear size argv[1] and exchanges messages with nearest neighbours. The messages are randoms numbers between 0 and 9. There are arg[2] rounds of exchange.");
        fprintf(stderr, "\nOptions:\n\n");
        fprintf(stderr, "-l    Linear size\n");
        fprintf(stderr, "-s    Sample size\n");
        fprintf(stderr, "-v    Verbose\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv, struct args_t *args){
	args->verbose = 0;
    int opt;
    while ((opt = getopt(argc, argv, "l:s:v:")) != -1) {
        switch (opt) {
            case 'l':
                args->lin_size = atoi(optarg);
                break;
            case 's':
                args->sample_size = atoi(optarg);
                break;
			case 'v':
				args->verbose = atoi(optarg);
				break;
            default:
                usage();
                break;
        }
    }
}


int main(int argc, char **argv)
{
	struct args_t args;
	parse_args(argc, argv, &args);
	int lin_size = args.lin_size;
	int numprocs, rank;
	int count, msg;
	int msg_send[lin_size], msg_recv[lin_size], neighbours[lin_size];
	int coords[2], dims[2] = {lin_size, lin_size}, is_periodic[2] = {1, 1}, sample_size = args.sample_size;
	char *fout_name;
	FILE *fout;
	MPI_Comm comm;


	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
	assert(numprocs == lin_size * lin_size);
	MPI_Cart_create(MPI_COMM_WORLD, 2, dims, is_periodic, 0, &comm);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Cart_coords(comm, rank, 2, coords);
	MPI_Cart_shift(comm, 0, 1, &neighbours[0], &neighbours[1]);
	MPI_Cart_shift(comm, 1, 1, &neighbours[2], &neighbours[3]);
	if(args.verbose) {
		asprintf(&fout_name, "out%d", rank);
		fout = fopen(fout_name, "w");
		fprintf(fout, "rank: %d\n", rank);
		fprintf(fout, "coords: (%d, %d)\n", coords[0], coords[1]);
		fprintf(fout, "neighbours: %d %d %d %d\n", neighbours[0], neighbours[1], neighbours[2], neighbours[3]);
	}
	srand(time(NULL) * rank);

	MPI_Request req[8];
	MPI_Status status[8];
	for(count = 0; count < sample_size; count++){
		for(msg = 0; msg < 4; msg++){
			msg_send[msg] = rand() % 10;
			MPI_Isend(&msg_send[msg], 1, MPI_INT, neighbours[msg], 0, comm, &req[msg]);
		}
		for(msg = 0; msg < 4; msg++){
			MPI_Irecv(&msg_recv[msg], 1, MPI_INT, neighbours[msg], 0, comm, &req[4 + msg]);
		}
		MPI_Waitall(8, req, status);
		if(args.verbose) {
			fprintf(fout, "round %d\n\tmsgs send: ", count);
			for(msg = 0; msg < 4; msg++){
				fprintf(fout, "%d ", msg_send[msg]);
			}
			fprintf(fout, "\n\tmsgs recv: ");
			for(msg = 0; msg < 4; msg++){
				fprintf(fout, "%d ", msg_recv[msg]);
			}
			fprintf(fout, "\n");
		}
	}
	if(args.verbose) close(fout);
	MPI_Finalize();
	return 0;
}
