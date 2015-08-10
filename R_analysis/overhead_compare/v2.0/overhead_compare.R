library("Hmisc")

path <- paste(getwd(), "/results/", sep="")

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}

gen_plot <- function(sample_size, delay, data_trace, data_calib, tracer) {

	data_overhead <- data_trace$mean - data_calib$mean
	#print(tracer)
	#print(data_calib)
	#print(data_trace)
	#print(data_overhead)

	x_label <- "number of threads"
	y_label <- "overhead (ns) per event"
	title <- paste(tracer, y_label, "according to the", x_label, "\nfor sample size", sample_size, ", delay of", delay, "increments")
	x_range <- range(data_trace$no_thread)
	y_range <- range(data_overhead)
	fig_name <- paste_path("figs/")
	fig_name <- paste(fig_name, tracer, "_size", sample_size, "_delay", delay, ".pdf", sep = "")
	no_threads <- levels(factor(data_trace$no_thread))
	no_threads_min <- log2(as.numeric(no_threads[[1]]))
	pdf(fig_name)
	par(mar=c(5, 4, 4, 5) + 0.1)
	plot(data_trace$no_thread, data_overhead, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
	lines(data_trace$no_thread, data_overhead, type = "b", lty = 4)
	#yticks_info=par("yaxp")
	ticks=2^seq(no_threads_min,no_threads_min + length(no_threads),1)
	axis(1, at=ticks, labels=ticks)
	#yticks <- seq(yticks_info[1], yticks_info[2], (yticks_info[2] - yticks_info[1]) / yticks_info[3] )
	fracs <- round(100 * data_overhead / data_calib$mean, digits=2)
	axis(4, at=data_overhead, labels=fracs)
	mtext("overhead (%)", side = 4, line = 3)
	dev.off()
}


data_calibration <- read.csv(paste_path("getuid_pthread_calibrate.csv"))

tracers <- c("ftrace", "perf", "lttng", "stap")
data_trace <- list()
for (i in 1:length(tracers)) {
	data_trace[[i]] <- read.csv(paste_path(paste("getuid_pthread_", tracers[[i]], ".csv", sep = "")))
	sample_sizes <- levels(factor(data_trace[[i]]$sample_size))
	delays <- levels(factor(data_trace[[i]]$delay))
	for (sample_size in sample_sizes) {
		for (delay in delays) {
			data_calib <- data_calibration[ which(data_calibration$delay == delay), ]
			data_calib$mean <- data_calib$mean /2
			data_tr <- data_trace[[i]][which(data_trace[[i]]$sample_size == sample_size & data_trace[[i]]$delay == delay), ]
			data_tr$mean <- data_tr$mean / 2
			gen_plot(sample_size, delay, data_tr, data_calib, tracers[i])
		}
	}
}

data_overhead <- list()
data_thread <- list()
for (sample_size in sample_sizes) {
	for (delay in delays) {
		for (i in 1:length(tracers)) {
			data_calib <- data_calibration[ which(data_calibration$delay == delay), ]
			data_calib$mean <- data_calib$mean /2
			data_tr <- data_trace[[i]][which(data_trace[[i]]$sample_size == sample_size & data_trace[[i]]$delay == delay), ]
			data_tr$mean <- data_tr$mean / 2
			data_overhead[[i]] <- data_tr$mean - data_calib$mean
			data_thread[[i]] <- data_tr$no_thread
		}
		xrange <- range(data_thread)
		yrange <- range(data_overhead)
		fig_name <- paste_path("figs/")
		fig_name <- paste(fig_name, "all_size", sample_size, "_delay", delay, ".pdf", sep = "")
		pdf(fig_name)
		plot(NULL, NULL, xlim = xrange, ylim = yrange, xlab="Number of threads", ylab="Overhead (ns) per event", main = paste("Overhead (ns) per event for various tracers\nsample_size", sample_size, "and delay", delay))
		for (i in 1:length(tracers)) {
			par(new=T)
			plot(data_thread[[i]], data_overhead[[i]], xlim = xrange, ylim = yrange, xlab="", ylab="", main="", pch = i)
			lines(data_thread[[i]], data_overhead[[i]], type = "c", lty = 4)
		}
		legend("topleft", tracers, pch=c(1:length(tracers)), title = "Tracer")
		dev.off()
	}
}
