path <- paste(getwd(), "/", sep="")
data_all <- read.csv(paste(path, "getuid_pthread_calibrate.csv", sep =""))

#rate is expressed as events / second -> converted to events / nanoseconds
args <- commandArgs(trailingOnly = TRUE)
print(args)
print(length(args))

#Each getuid call generates two events
data_all$mean <- data_all$mean / 2
print(data_all)

no_ths <- levels(factor(data_all$no_th))
#print(no_ths)

fit <- list()
for (no_th in no_ths) {
	data <- data_all[which(data_all$no_th == no_th), ]
	#cor(data$delay, data$mean)
	fit <- lm(data$mean ~ data$delay)
	summary(fit)
	pdf(paste(path, "calibrate_plot_noth=", no_th, ".pdf", sep = ""))
	plot(data$delay, data$mean, xlab = "number of \"x++\" iterations", ylab= "average time per event", main = "Calibration of getuid_pthread")
	abline(fit)
	dev.off()
	#Estimate required delay to otbain target event rate
	coe <- coef(fit)
	sink(paste("calibrate_noth=", no_th, ".result", sep = ""))
	for (i in 1:length(args)) {
		rate <- as.numeric(args[i]) / 10^9
		desired <- 1 / rate
		delay <- (desired - coe[["(Intercept)"]]) / coe[["data$delay"]]
		sds <- coef(summary(fit))
		er <- sds[, 2][["(Intercept)"]] + sds[, 2][["data$delay"]] * delay
		max <- 10^9 / coe[["(Intercept)"]]
		max_er <- 10^9 / (coe[["(Intercept)"]] - sds[, 2][["(Intercept)"]]) - max
		cat(paste("rate: ", args[i], sep=""))
		cat(paste(" delay: ", round(delay, digits = 0), sep=""))
		cat(paste(" pm ", round(er, digits = 0)), " (", round(100 * er/delay, digits = 3), "%)\n", sep= "")
		#cat(paste("max rate: ", round(max, digits = 0), " (pm ", round(100 * max_er / max, digits = 0), "%)\n", sep = ""))
	}
	sink()
}
