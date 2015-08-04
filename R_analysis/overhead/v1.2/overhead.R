library("Hmisc")

path <- paste(getwd(), "/results/", sep="")

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}

gen_plot <- function(no_thread, sample_size, output, overflow, delay, data, data_calib) {

	total_buf_sizes <- levels(factor(data$total_buf_size))
	data_num_subbuf <- list()
	data_overhead <- list()
	for(i in 1:length(total_buf_sizes)) {
		data_num_subbuf[[i]] <- subset(data, total_buf_size == total_buf_sizes[[i]])
		data_overhead[[i]] <- data_num_subbuf[[i]]$mean - data_calib$mean
	}
	num_subbufs <- levels(factor(data$num_subbuf))
	x_min_num_subbufs <- log2(as.numeric(num_subbufs[[1]]))

	x_label <- "number of subbuffers"
	y_label <- "overhead (ns) per event"
	title <- paste("Lttng", y_label, "according to the", x_label, "\nfor", no_thread, "threads, sample size", sample_size, ", delay of", delay, "increments,\n channel mode:", output, overflow)
	x_range <- range(data$num_subbuf)
	y_range <- range(data_overhead)
	fig_name <- paste_path("figs/")
	fig_name <- paste(fig_name, "noth", no_thread, "_size", sample_size, "_output", output, "_overflow", overflow, "_delay", delay, ".pdf", sep = "")
	pdf(fig_name)
	par(mar=c(5, 4, 4, 5) + 0.1)
	plot(data_num_subbuf[[1]]$num_subbuf, data_overhead[[1]], xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
	lines(data_num_subbuf[[1]]$num_subbuf, data_overhead[[1]], type = "c", lty = 4)
	yticks_info=par("yaxp")
	if (length(total_buf_sizes) > 1) {
		for (i in 2:length(total_buf_sizes)) {
			par(new=T)
			plot(data_num_subbuf[[i]]$num_subbuf, data_overhead[[i]], xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", pch=i)
			lines(data_num_subbuf[[i]]$num_subbuf, data_overhead[[i]], type = "c", lty = 4)
		}
	}
	ticks=2^seq(x_min_num_subbufs,x_min_num_subbufs + length(num_subbufs),1)
	axis(1, at=ticks, labels=ticks)
	yticks <- seq(yticks_info[1], yticks_info[2], (yticks_info[2] - yticks_info[1]) / yticks_info[3] )
	fracs <- round(100 * yticks / data_calib$mean, digits=2)
	axis(4, at=yticks, labels=fracs)
	mtext("overhead (%)", side = 4, line = 3)
	legend("topright", total_buf_sizes, pch = c(1:length(total_buf_sizes)), title = "buffer size (kb)")
	dev.off()
}


data_calibration <- read.csv(paste_path("getuid_pthread_calibrate.csv"))
data <- read.csv(paste_path("getuid_pthread_lttng.csv"))
print(data)
no_threads <- levels(factor(data$no_thread))
print(no_threads)
sample_sizes <- levels(factor(data$sample_size))
print(sample_sizes)
outputs <- levels(data$output)
print(outputs)
overflows <- levels(data$overflow)
print(overflows)
delays <- levels(factor(data$delay))
print(delays)

for (no_thread in no_threads) {
	for (sample_size in sample_sizes) {
		for (output in outputs) {
			for (overflow in overflows) {
				for (delay in delays) {
					data_calib <- data_calibration[ which(data_calibration$delay == delay & data_calibration$no_th == no_thread),]
					data_calib$mean <- data_calib$mean / 2
					data_set <- data[which(data$no_thread == no_thread & data$sample_size == sample_size & data$output == output & data$overflow == overflow & data$delay == delay), ]
					data_set$mean <- data_set$mean / 2
					gen_plot(no_thread, sample_size, output, overflow, delay, data_set, data_calib)
				}
			}
		}
	}
}
