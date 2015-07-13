path <- "~/git/compare_tracers/scripts/lttng/v5.0/"

no_repetitions <- 16
data_list <- list()
for(i in 1:no_repetitions) {
  data_list[[i]] <- read.csv(paste(path, "getuid_pthread_lttng_", toString(i), ".csv", sep =""))
}
no_params_sets <- nrow(data_list[[1]])
means <- vector(mode = "integer", length = no_params_sets)
sds <- vector(mode = "integer", length = no_params_sets)
frac_lost_events <- vector(mode = "integer", length = no_params_sets)
for(i in 1:no_repetitions) {
  means <- means + data_list[[i]]$mean
  sds <- sds + (data_list[[i]]$std)^2
  frac_lost_events <- frac_lost_events + data_list[[i]]$frac_lost_events
}
means <- means / no_repetitions
means <- format(round(means, 2), nsmall = 2)
sds <- sds / no_repetitions
sds <- sqrt(sds)
sds <- format(round(sds, 2), nsmall = 2)
frac_lost_events <- frac_lost_events / no_repetitions
frac_lost_events <- format(round(frac_lost_events, 2), nsmall = 2)

data <- data_list[[1]]
data$mean <- means
data$std  <- sds
data$frac_lost_events <- frac_lost_events
data$sample_size <- data$sample_size * no_repetitions

write.csv(data, paste(path, "getuid_pthread_lttng.csv", sep =""), row.names=FALSE, quote=FALSE)
