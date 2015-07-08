library("Hmisc")
library("plotrix")

path <- "git/compare_tracers/objective10.3/getuid_pthread_lttng.csv"

data <- read.csv(path)
size <- 8388608
data <- subset(data, sample_size == size)
print(data)

subbuf_sizes <- levels(factor(data$subbuf_size))
data_num_subbuf <- list()
for(i in 1:length(subbuf_sizes)) {
  data_num_subbuf[[i]] <- subset(data, subbuf_size == subbuf_sizes[[i]])
}
print(data_num_subbuf)

x_label <- "Number of subbufers"
y_label <- "Number of lost events"
y_range <- range(data$no_lost_events)
pdf("git/compare_tracers/objective10.3/figs/num_subbuf.pdf")
plot(data_num_subbuf[[1]]$num_subbuf, data_num_subbuf[[1]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", main="Number of lost events as a function of the number of buffers\n for various subbuffer sizes", pch=1)
ticks <- seq(2, 5, by=1)
labels <- sapply(ticks, function(x) as.expression(bquote(2^ .(x))))
axis(1, at=c(4, 8, 16, 32), labels=labels)
for(i in 2:length(subbuf_sizes)) {
  par(new=T)
  plot(data_num_subbuf[[i]]$num_subbuf, data_num_subbuf[[i]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", pch=i)
}
legend("topright", subbuf_sizes, pch = c(1:length(subbuf_sizes)), title = "subbufer size (kb)")
dev.off()

y_range <- range(sapply(data$no_lost_events, function(x) max(1,x)))
data_to_plot <- sapply(data_num_subbuf[[1]]$no_lost_events, function(x) max(1, x))
plot(data_num_subbuf[[1]]$num_subbuf, data_to_plot, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", xaxt="n", main="Number of lost events as a function of the number of buffers\n for various subbuffer sizes", pch=1)
ticks <- seq(2, 5, by=1)
labels <- sapply(ticks, function(x) as.expression(bquote(2^ .(x))))
axis(1, at=c(4, 8, 16, 32), labels=labels)
for(i in 2:length(subbuf_sizes)) {
  par(new=T)
  data_to_plot <- sapply(data_num_subbuf[[i]]$no_lost_events, function(x) max(1, x))
  plot(data_num_subbuf[[i]]$num_subbuf, data_to_plot, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", xaxt="n", pch=i)
}
legend("bottomleft", subbuf_sizes, pch = c(1:length(subbuf_sizes)), title = "subbuffer size (kb)")


num_subbufs <- levels(factor(data$num_subbuf))
print(num_subbufs)
data_subbuf_sizes<- list()
for(i in 1:length(num_subbufs)) {
  data_subbuf_sizes[[i]] <- subset(data, num_subbuf == num_subbufs[[i]])
}
print(data_subbuf_sizes)

x_label <- "Subbuffer sizes (kb)"
y_label <- "Number of lost events"

y_range <- range(data$no_lost_events)
pdf("git/compare_tracers/objective10.3/figs/subbuf_size.pdf")
plot(data_subbuf_sizes[[1]]$subbuf_size, data_subbuf_sizes[[1]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, main="Number of lost events as a function of the subbuffers sizes\n for various number of subbuffers", pch=1)
for(i in 2:length(num_subbufs)) {
  par(new=T)
  plot(data_subbuf_sizes[[i]]$subbuf_size, data_subbuf_sizes[[i]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, pch=i)
}
legend("topright", num_subbufs, pch = c(1:length(num_subbufs)), title = "number of subbuffers")
dev.off()

y_range <- range(sapply(data$no_lost_events, function(x) max(1,x)))
data_to_plot <- sapply(data_subbuf_sizes[[1]]$no_lost_events, function(x) max(1,x))
plot(data_subbuf_sizes[[1]]$subbuf_size, data_to_plot, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", main="Number of lost events as a function of the subbuffers sizes\n for various number of subbuffers", pch=1)
for(i in 2:length(num_subbufs)) {
  par(new=T)
  data_to_plot <- sapply(data_subbuf_sizes[[i]]$no_lost_events, function(x) max(1,x))
  plot(data_subbuf_sizes[[i]]$subbuf_size, data_to_plot, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", pch=i)
}
legend("bottomleft", num_subbufs, pch = c(1:length(num_subbufs)), title = "number of subbuffers")

x_label <- "Total buffer size (kb)"
y_label <- "Number of lost events"

y_range <- range(sapply(data$no_lost_events, function(x) max(1,x)))
#y_range <- c(1000000, 20000000)
x_range <- range(data$subbuf_size * data$num_subbuf)
#x_range <- c(16,1200)
pdf("git/compare_tracers/objective10.3/figs/total_buf_size.pdf")
data_x <- data_subbuf_sizes[[1]]$subbuf_size * data_subbuf_sizes[[1]]$num_subbuf
data_y <- sapply(data_subbuf_sizes[[1]]$no_lost_events, function(x) max(1,x))
plot(data_x , data_y, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", xaxt="n", main="Number of lost events as a function of the total buffer size", pch=1)
ticks <- seq(4, 12, by=1)
labels <- sapply(ticks, function(x) as.expression(bquote(2^ .(x))))
axis(1, at=c(16, 32, 64, 128, 256, 512, 1024, 2048, 4096), labels=labels)
for(i in 2:length(num_subbufs)) {
  par(new=T)
  data_x <- data_subbuf_sizes[[i]]$subbuf_size * data_subbuf_sizes[[i]]$num_subbuf
  data_y <- sapply(data_subbuf_sizes[[i]]$no_lost_events, function(x) max(1,x))
  plot(data_x, data_y, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="xy", pch=i)
}
legend("bottomleft", num_subbufs, pch = c(1:length(num_subbufs)), title = "number of subbuffers")
dev.off()

y_range <- range(sapply(data$no_lost_events, function(x) max(1000,x)))
#y_range <- c(1000000, 20000000)
x_range <- range(data$subbuf_size * data$num_subbuf)
#x_range <- c(16,1200)
pdf("git/compare_tracers/objective10.3/figs/total_buf_size.pdf")
data_x <- data_subbuf_sizes[[1]]$subbuf_size * data_subbuf_sizes[[1]]$num_subbuf
data_y <- sapply(data_subbuf_sizes[[1]]$no_lost_events, function(x) max(1,x))
plot(data_x , data_y, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, log="xy", xaxt="n", yaxt="n", main="Number of lost events as a function of the total buffer size", pch=1)
ticks <- seq(4, 12, by=1)
labels <- sapply(ticks, function(x) as.expression(bquote(2^ .(x))))
axis(1, at=c(16, 32, 64, 128, 256, 512, 1024, 2048, 4096), labels=labels)
axis(2, at=c(10^3, 10^4, 10^5, 10^6, 10^7), labels=c(1, 10^4, 10^5, 10^6, 10^7))
axis.break(2, 3162, style="slash")
for(i in 2:length(num_subbufs)) {
  par(new=T)
  data_x <- data_subbuf_sizes[[i]]$subbuf_size * data_subbuf_sizes[[i]]$num_subbuf
  data_y <- sapply(data_subbuf_sizes[[i]]$no_lost_events, function(x) max(1000,x))
  plot(data_x, data_y, xlim=x_range, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", yaxt="n", log="xy", pch=i)
}
legend("bottomleft", num_subbufs, pch = c(1:length(num_subbufs)), title = "number of subbuffers")
dev.off()