library("Hmisc")

path <- "git/compare_tracers/R_analysis/lost_events_analysis/results/"

paste_path <- function(filename){
  ret <- paste(path, filename, sep="")
  return(ret)
}

paste_path("getuid_pthread_lttng.csv")

data <- read.csv(paste_path("getuid_pthread_lttng.csv"))
size <- 1048576
data <- subset(data, sample_size == size)
print(data)

subbuf_sizes <- levels(factor(data$subbuf_size))
print(subbuf_sizes)
x_min_subbuf_sizes <- log2(as.numeric(subbuf_sizes[[1]]))
data_num_subbuf <- list()
for(i in 1:length(subbuf_sizes)) {
  data_num_subbuf[[i]] <- subset(data, subbuf_size == subbuf_sizes[[i]])
}
print(data_num_subbuf)
num_subbufs <- levels(factor(data$num_subbuf))
print(num_subbufs)
x_min_num_subbufs <- log2(as.numeric(num_subbufs[[1]]))
data_subbuf_sizes<- list()
for(i in 1:length(num_subbufs)) {
  data_subbuf_sizes[[i]] <- subset(data, num_subbuf == num_subbufs[[i]])
}
print(data_subbuf_sizes)

x_label <- "Number of subbufers"
y_label <- "Fraction of lost events"
title <- paste(y_label, "as a function of", x_label, "for various subbuffer sizes and sample size", size)
y_range <- range(data$no_lost_events)
pdf(paste_path("figs/num_subbuf.pdf"))
plot(data_num_subbuf[[1]]$num_subbuf, data_num_subbuf[[1]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
ticks=2^seq(x_min_num_subbufs,x_min_num_subbufs + length(num_subbufs),1)
axis(1, at=ticks, labels=ticks)
for(i in 2:length(subbuf_sizes)) {
  par(new=T)
  plot(data_num_subbuf[[i]]$num_subbuf, data_num_subbuf[[i]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", pch=i)
}
legend("bottomleft", subbuf_sizes, pch = c(1:length(subbuf_sizes)), title = "subbufer size (kb)")
dev.off()


x_label <- "Subbuffer sizes"
y_label <- "Fraction of lost events"
title <- paste(y_label, "as a function of", x_label, "for various num of subbufers and sample size", size)
y_range <- range(data$no_lost_events)
pdf(paste_path("figs/subbuf_size.pdf"))
plot(data_subbuf_sizes[[1]]$subbuf_size, data_subbuf_sizes[[1]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", main=title, pch=1)
ticks=2^seq(x_min_subbuf_sizes,x_min_subbuf_sizes + length(subbuf_sizes),1)
axis(1, at=ticks, labels=ticks)
for(i in 2:length(num_subbufs)) {
  par(new=T)
  plot(data_subbuf_sizes[[i]]$subbuf_size, data_subbuf_sizes[[i]]$no_lost_events, ylim=y_range, xlab=x_label, ylab=y_label, xaxt="n", log="x", pch=i)
}
legend("bottomleft", num_subbufs, pch = c(1:length(num_subbufs)), title = "number of subbuffers")
dev.off()


