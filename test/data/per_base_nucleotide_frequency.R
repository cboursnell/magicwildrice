library(ggplot2)
library(reshape2)

setwd("~/documents/scripts/rice/test/data")

data <- read.table("test_base_counts.txt",header=T)

rownames(data) <- data[,1]
data <- data[,2:ncol(data)]
apply(data, 1, function(x) { x / sum(x) } )
data <- as.data.frame(t(apply(data, 1, function(x) { x / sum(x) } )))

data$base <- rownames(data)
data$base <- as.numeric(as.character(data$base))

mdata <- melt(data, id.vars="base")

ggplot(mdata, aes(x=base, y=value, group=variable)) +
  geom_line(aes(colour=variable)) +
  ggsave("per_base_count.pdf")

