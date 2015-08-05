gen_plot <- function(data, name) {
	numprocs <- levels(factor(data$num_procs))
	pdf(paste(path, "results/paraver_MPI_", name, ".pdf", sep=""))
	x_range <- range(data$num_MPI_msgs)
	#print(x_range)
	y_range <- range(data$time)
	#print(y_range)
	plot(NULL, NULL, xlim=x_range, ylim=y_range, xlab="number of MPI Isend & Irecv", ylab="total time to run workload (s)", main = paste("Time to run MPI workload (", name, ")\nfor various number of processes (num_procs)", sep=""), pch=1)
	for (i in 1:length(numprocs)) {
		numproc <- numprocs[i]
		data_tmp <- data[which(data$num_procs == numproc), ]
		#fit <- lm(data_tmp$time ~ data_tmp$num_MPI_msgs)
		par(new = T)
		plot(data_tmp$num_MPI_msgs, data_tmp$time, xlim=x_range, ylim=y_range, xlab="", ylab="", pch=i)
		lines(data_tmp$num_MPI_msgs, data_tmp$time, type = "c", lty = 4)
		#abline(fit)
	}
	legend("topleft", numprocs, pch=c(1:length(numprocs)), title = "num_procs")
	dev.off()
}

path <- paste(getwd(), "/", sep="")
data_calibration <- read.csv(paste(path, "results/paraver_MPI.calibration.csv", sep =""))
data_paraver <- read.csv(paste(path, "results/paraver_MPI.ld_preload.csv", sep =""))
#print(data_calibration)

options(scipen=-3)
gen_plot(data_calibration, "calibration")
gen_plot(data_paraver, "paraver")


