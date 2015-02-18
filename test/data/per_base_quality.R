library(ggplot2)
library(reshape2)

setwd("~/documents/scripts/rice/")

data <- read.table("test_1.fastq-per_base_quality_tile.txt", header=T)

rownames(data) <- data[,1]
data <- data[,2:ncol(data)]

data <- as.data.frame(t(apply(data, 1, function(x) { x / sum(x) } )))

names(data) <- gsub(names(data), pattern="X", replacement="")
names(data) <- as.numeric(as.character(names(data)))
data$base <- rownames(data)
data$base <- as.numeric(as.character(data$base))
summary(data)
mdata <- melt(data, id.vars="base")
summary(mdata)
mdata$variable <- as.numeric(as.character(mdata$variable))
summary(mdata)
names(mdata) <- c("base", "quality", "value")


ggplot(mdata, aes(x=base, y=quality)) +
  geom_tile(aes(fill=value)) +
  scale_fill_gradient2(low="white", high="red", space="Lab", na.value = "grey50", guide="colorbar")
