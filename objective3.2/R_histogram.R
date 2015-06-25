data <- scan("git/compare_tracers/objective3.2/sample")

#plot(data)

mean <- mean(data)
sd <- sd(data)

relevant <- data[data < (mean + 5 * sd)]
length(relevant) / length(data)
#plot(relevant)
#sd of 5 * sigmas : 99.9999426697%
sd(relevant)

outlier <- data[data > (mean + 5 * sd)]
plot(outlier)

data_hist <- hist(data, plot = F)
data_hist$count <- data_hist$count + 1
barplot(data_hist$count, log="y")

relevant_hist <- hist(relevant, plot = F)
barplot(relevant_hist$count, log="y")

outlier_hist <- hist(outlier, plot = F)
outlier_hist$count <- outlier_hist$count + 1
barplot(outlier_hist$count, log="y")