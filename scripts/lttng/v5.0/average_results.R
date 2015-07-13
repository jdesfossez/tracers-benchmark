path <- paste(getwd(), "/", sep="")

format_output <- function(x, y) {
  return(format(round(x, y), nsmall = y))
}

args <- commandArgs(trailingOnly = TRUE)
no_repetitions <- as.numeric(args[1])

data <- read.csv(paste(path, "getuid_pthread_lttng_1.csv", sep =""))
for(i in 2:no_repetitions) {
  data <- rbind(data, read.csv(paste(path, "getuid_pthread_lttng_", toString(i), ".csv", sep ="")))
}


data_average <- data.frame(mean=numeric(), m_sd=numeric(), frac_lost_events=numeric(), f_sd=numeric(), trace_size=numeric(), t_sd=numeric(), output=character(), overflow=character(), num_subbuf=numeric(), total_buf_size=numeric(), no_thread=numeric(), sample_size=numeric(), delay=numeric(), no_repetitions=numeric())
for(output_op in levels(data$output)) {
  for(overflow_op in levels(data$overflow)) {
    for(num_subbuf_op in levels(factor(data$num_subbuf))) {
      for(total_buf_size_op in levels(factor(data$total_buf_size))) {
        for(no_thread_op in levels(factor(data$no_thread))) {
          for(delay_op in levels(factor(data$delay))) {
            for(sample_size_op in levels(factor(data$sample_size))) {
              data_tmp <- data[which(data$output == output_op & data$overflow == overflow_op & data$num_subbuf == num_subbuf_op & data$total_buf_size == total_buf_size_op & data$no_thread == no_thread_op & data$sample_size == sample_size_op & data$delay == delay_op), ]
              m <- format_output(mean(data_tmp$mean), 2)
              msd <- format_output(sd(data_tmp$mean), 2)
              f <- format_output(mean(data_tmp$frac_lost_events), 2)
              fsd <- format_output(sd(data_tmp$frac_lost_events), 2)
              t <-format_output(mean(data_tmp$trace_size), 0)
              tsd <- format_output(sd(data_tmp$trace_size), 0)
              c(m, msd, f, fsd, t, tsd, output_op, overflow_op, num_subbuf_op, total_buf_size_op, no_thread_op, sample_size_op, delay_op, no_repetitions)
              data_average <- rbind(data_average, data.frame(mean=m, m_sd=msd, frac_lost_events=f, f_sd=fsd, trace_size=t, t_sd=tsd, output=output_op, overflow=overflow_op, num_subbuf=num_subbuf_op, total_buf_size=total_buf_size_op, no_thread=no_thread_op, sample_size=sample_size_op, delay=delay_op, no_repetitions=no_repetitions))
            }
          }
        }
      }
    }
  }
}

write.csv(data_average, paste(path, "getuid_pthread_lttng.csv", sep =""), row.names=FALSE, quote=FALSE)
