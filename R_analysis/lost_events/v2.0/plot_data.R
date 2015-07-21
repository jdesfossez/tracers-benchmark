library("Hmisc")

path <- "git/compare_tracers/R_analysis/lost_events_analysis/v2.0/results/"

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}

paste_path("getuid_pthread_lttng.csv")

data <- read.csv(paste_path("getuid_pthread_lttng.csv"))
size <- 1048576
data <- subset(data, sample_size == size)
print(data)

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
y_label <- "Fraction of lost events"
title <- paste(y_label, "according to", x_label, "\nfor various total buffer sizes and sample size", size)
x_range <- range(data$num_subbuf)
y_range <- range(data$no_lost_events)
pdf(paste_path("figs/num_subbuf.pdf"))
plot(data_num_subbuf[[1]]$num_subbuf, data_num_subbuf[[1]]$no_lost_events, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
for(i in 2:length(total_buf_sizes)) {
  par(new=T)
  plot(data_num_subbuf[[i]]$num_subbuf, data_num_subbuf[[i]]$no_lost_events, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", pch=i)
}
ticks=2^seq(x_min_num_subbufs,x_min_num_subbufs + length(num_subbufs),1)
axis(1, at=ticks, labels=ticks)
legend("bottomleft", total_buf_sizes, pch = c(1:length(total_buf_sizes)), title = "buffer size (kb)")
dev.off()