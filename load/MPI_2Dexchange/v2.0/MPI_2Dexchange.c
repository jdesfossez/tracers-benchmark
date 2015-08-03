#include <assert.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

struct args_t {
    int height;
	int width;
    int sample_size;
	int verbose;
};

__attribute__((noreturn))
void usage(void) {
        fprintf(stderr, "Usage: MPI_2Dexchange [OPTIONS] [COMMAND]\n");
        fprintf(stderr, "Program that creates a 2D rectangular lattice and exchanges messages with nearest neighbours. The messages are randoms numbers between 0 and 9. There are sample_size rounds of exchange.");
        fprintf(stderr, "\nOptions:\n\n");
        fprintf(stderr, "-h    Height\n");
		fprintf(stderr, "-w    Width\n");
        fprintf(stderr, "-s    Sample size\n");
        fprintf(stderr, "-v    Verbose\n");
        exit(EXIT_FAILURE);
}

void parse_args(int argc, char **argv, struct args_t *args){
	args->verbose = 0;
    int opt;
    while ((opt = getopt(argc, argv, "h:w:s:v:")) != -1) {
        switch (opt) {
            case 'h':
                args->height = atoi(optarg);
                break;
			case 'w':
				args->width = atoi(optarg);
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
	int height = args.height, width = args.width;
	int numprocs, rank;
	int count, msg;
	int msg_send[4], msg_recv[4], neighbours[4];
	int coords[2], dims[2] = {height, width}, is_periodic[2] = {1, 1}, sample_size = args.sample_size;
	char *fout_name;
	FILE *fout;
	MPI_Comm comm;


	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
	assert(numprocs == height * width);
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
