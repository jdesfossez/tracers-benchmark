library("Hmisc")

path <- paste(getwd(), "/results/", sep="")

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}

gen_plot <- function(no_thread, sample_size, output, overflow, delay, data) {

	total_buf_sizes <- levels(factor(data$total_buf_size))
	print(total_buf_sizes)
	data_num_subbuf <- list()
	for(i in 1:length(total_buf_sizes)) {
		data_num_subbuf[[i]] <- subset(data, total_buf_size == total_buf_sizes[[i]])
	}
	print(data_num_subbuf)
	num_subbufs <- levels(factor(data$num_subbuf))
	print(num_subbufs)
	x_min_num_subbufs <- log2(as.numeric(num_subbufs[[1]]))
	print(x_min_num_subbufs)

	x_label <- "number of subbuffers"
	y_label <- "number of lost events"
	title <- paste(y_label, "according to the", x_label, "\nfor", no_thread, "threads, sample size", sample_size, ", delay of", delay, "increments,\n channel mode:", output, overflow)
	x_range <- range(data$num_subbuf)
	y_range <- range(data$no_lost_events)
	print(x_range)
	print(y_range)
	fig_name <- paste_path("figs/")
	fig_name <- paste(fig_name, "noth", no_thread, "_size", sample_size, "_output", output, "_overflow", overflow, "_delay", delay, ".pdf", sep = "")
	pdf(fig_name)
	non_zeros <- data_num_subbuf[[1]][ which(data_num_subbuf[[1]]$no_lost_events!=0), ]
	plot(non_zeros$num_subbuf, non_zeros$no_lost_events, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
	zeros <- data_num_subbuf[[1]][ which(data_num_subbuf[[1]]$no_lost_events==0), ]
	yticks_info=par("yaxp")
	points(zeros$num_subbuf, zeros$no_lost_events, col="green", pch=1)
	if (length(total_buf_sizes) > 1) {
		for (i in 2:length(total_buf_sizes)) {
			par(new=T)
			non_zeros <- data_num_subbuf[[i]][ which(data_num_subbuf[[i]]$no_lost_events!=0), ]
			plot(non_zeros$num_subbuf, non_zeros$no_lost_events, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", pch=i)
			print(data_num_subbuf[[i]])
			zeros <- data_num_subbuf[[i]][ which(data_num_subbuf[[i]]$no_lost_events==0), ]
			points(zeros$num_subbuf, zeros$no_lost_events, col="green", pch=i)
		}
	}
	ticks=2^seq(x_min_num_subbufs,x_min_num_subbufs + length(num_subbufs),1)
	axis(1, at=ticks, labels=ticks)
	yticks <- seq(yticks_info[1], yticks_info[2], (yticks_info[2] - yticks_info[1]) / yticks_info[3] )
	fracs <- round(yticks / data_num_subbuf[[i]]$no_events_expected[1], digits=3)
	axis(4, at=yticks, labels=fracs)
	legend("topright", total_buf_sizes, pch = c(1:length(total_buf_sizes)), title = "buffer size (kb)")
	dev.off()
}

paste_path("getuid_pthread_lttng.csv")

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
					data_set <- data[which(data$no_thread == no_thread & data$sample_size == sample_size & data$output == output & data$overflow == overflow & data$delay == delay), ]
					gen_plot(no_thread, sample_size, output, overflow, delay, data_set)
				}
			}
		}
	}
}
