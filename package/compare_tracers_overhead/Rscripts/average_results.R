path <- paste(getwd(), "/", sep="")

format_output <- function(x, y) {
  return(format(round(x, y), nsmall = y))
}

args <- commandArgs(trailingOnly = TRUE)
tracer <- args[1]
no_repetitions <- as.numeric(args[2])

data <- read.csv(paste(path, "getuid_pthread_", tracer, "_1.csv", sep =""))
for(i in 2:no_repetitions) {
  data <- rbind(data, read.csv(paste(path, "getuid_pthread_", tracer, "_", toString(i), ".csv", sep ="")))
}
#print(data)


data_average <- data.frame(mean=numeric(), m_sd=numeric(), no_lost_events=numeric(), l_sd=numeric(), no_events_expected=numeric(), trace_size=numeric(), t_sd=numeric(), no_thread=numeric(), sample_size=numeric(), delay=numeric(), no_repetitions=numeric())
for(no_expected in levels(factor(data$no_events_expected))) {
 for(no_thread_op in levels(factor(data$no_thread))) {
  for(delay_op in levels(factor(data$delay))) {
   for(sample_size_op in levels(factor(data$sample_size))) {
     data_tmp <- data[which(data$no_events_expected == no_expected  & data$no_thread == no_thread_op & data$sample_size == sample_size_op & data$delay == delay_op), ]
        if (nrow(data_tmp) == 0) next
        m <- format_output(mean(data_tmp$mean), 2)
        msd <- format_output(sd(data_tmp$mean), 2)
        l <- format_output(mean(data_tmp$no_lost_events), 0)
        lsd <- format_output(sd(data_tmp$no_lost_events), 0)
        t <-format_output(mean(data_tmp$trace_size), 0)
        tsd <- format_output(sd(data_tmp$trace_size), 0)
        c(m, msd, l, lsd, no_expected, t, tsd, no_thread_op, sample_size_op, delay_op, no_repetitions)
        data_average <- rbind(data_average, data.frame(mean=m, m_sd=msd, no_lost_events=l, l_sd=lsd, no_events_expected=no_expected, trace_size=t, t_sd=tsd, no_thread=no_thread_op, sample_size=sample_size_op, delay=delay_op, no_repetitions=no_repetitions))
   }
  }
 }
}

write.csv(data_average, paste(path, "getuid_pthread_", tracer, ".csv", sep =""), row.names=FALSE, quote=FALSE)
