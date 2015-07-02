library("Hmisc")

path <- "git/compare_tracers/objective10.2/results/"

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}
data_paths <- sapply(c("getuid_pthread_calibration.csv", "getuid_pthread_lttng.csv", "getuid_pthread_lttng_snapshot.csv", "getuid_pthread_system_tap.csv", "getuid_pthread_perf.csv", "getuid_pthread_ftrace.csv"), paste_path)
fig_paths <- sapply(c("figs/calibration.pdf","figs/lttng.pdf", "figs/lttng_snapshot.pdf", "figs/system_tap.pdf", "figs/perf.pdf", "figs/ftrace.pdf"), paste_path)

print(data_paths)

make_title <- function(tracer){
  if(tracer == 1) title <- "Calibration"
  if(tracer == 2) title <- paste("Lttng\noutput = ", data[[tracer]]$output[1], ",", data[[tracer]]$overflow[1], ", num-subbuf =", data[[tracer]]$num_subbuf[1], ", subbuf-size =", data[[tracer]]$subbuf_size[1], "k")
  if(tracer == 3) title <- paste("Lttng\nSnapshot mode, output = ", data[[tracer]]$num_subbuf[1], ", subbuf-size =", data[[tracer]]$subbuf_size[1], "k")
  if(tracer == 4) title <- "System tap"
  if(tracer == 5) title <- "Perf"
  if(tracer == 6) title <- "Ftrace (trace-cmd)"
  return(title)
}

data <- list()
for(i in 1:6) {
  data[[i]] <- read.csv(data_paths[i])
}

x_label <- "Number of threads"
y_label <- "Mean time (ns) per clock_gettime + getuid syscall"

print(data[[1]])
pdf(fig_paths[1])
plot(data[[1]]$no_thread, data[[1]]$mean, xlab=x_label, ylab=y_label, main=make_title(1))
dev.off()
data_calib <- data[[1]]
for (i in 2:6 ) {
  print(data[[i]])
  pdf(fig_paths[i])
  plot(data[[i]]$no_thread, data[[i]]$mean, xlab=x_label, ylab=y_label, main=make_title(i))
  dev.off()
}

x_label <- "Number of threads"
y_label <- "Mean overhead (ns) per clock_gettime + getuid syscall"
fig_paths <- sapply(c("figs/calibration.pdf","figs/lttng_overhead.pdf", "figs/lttng_snapshot_overhead.pdf", "figs/system_tap_overhead.pdf", "figs/perf_overhead.pdf", "figs/ftrace_overhead.pdf"), paste_path)

for (i in 2:6 ) {
  print(data[[i]])
  pdf(fig_paths[i])
  overhead <- data[[i]]$mean - data_calib$mean
  plot(data[[i]]$no_thread, overhead, xlab=x_label, ylab=y_label, main=make_title(i))
  dev.off()
}

x_label <- "Number of threads"
y_label <- "Overhead relative to each clock_gettime + getuid syscall"
fig_paths <- sapply(c("figs/calibration.pdf","figs/lttng_relative_overhead.pdf", "figs/lttng_snapshot_relative_overhead.pdf", "figs/system_tap_relative_overhead.pdf", "figs/perf_relative_overhead.pdf", "figs/ftrace_relative_overhead.pdf"), paste_path)

for (i in 2:6 ) {
  print(data[[i]])
  pdf(fig_paths[i])
  overhead <- (data[[i]]$mean - data_calib$mean) / data_calib$mean
  plot(data[[i]]$no_thread, overhead, ylim=range(c(0, overhead)), xlab=x_label, ylab=y_label, main=make_title(i))
  dev.off()
}

x_label <- "Number of threads"
y_label <- "Mean time (ns) per clock_gettime + getuid syscall"
data_stap <- subset(data[[4]], probe_content=="print entry and exit to file with gettimeofday_us() timestamp")
y_range <- range(c(data[[2]]$mean, data[[3]]$mean, data_stap$mean, data[[5]]$mean, data[[6]]$mean))
print(data[[6]])
pdf(paste_path("figs/all.pdf"))
plot(data[[2]]$no_thread, data[[2]]$mean, ylim=y_range, xlab=x_label, ylab=y_label, pch=1)
par(new=T)
plot(data[[3]]$no_thread, data[[3]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=2)
par(new=T)
plot(data_stap$no_thread, data_stap$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=3)
par(new=T)
plot(data[[5]]$no_thread, data[[5]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=4)
par(new=T)
plot(data[[6]]$no_thread, data[[6]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=5)
legend("topleft", c("lttng","lttng snapshot","system tap","perf","ftrace (trace-cmd)"), pch = c(1,2,3,4,5))
dev.off()

y_range <- c(1000, 5000)
pdf(paste_path("figs/all_zoom_y.pdf"))
plot(data[[2]]$no_thread, data[[2]]$mean, ylim=y_range, xlab=x_label, ylab=y_label, pch=1)
par(new=T)
plot(data[[3]]$no_thread, data[[3]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=2)
par(new=T)
plot(data_stap$no_thread, data_stap$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=3)
par(new=T)
plot(data[[5]]$no_thread, data[[5]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=4)
par(new=T)
plot(data[[6]]$no_thread, data[[6]]$mean, ylim=y_range, axes=F, xlab="", ylab="", pch=5)
legend("bottomright", c("lttng","lttng snapshot","system tap","perf","ftrace (trace-cmd)"), pch = c(1,2,3,4,5))
dev.off()