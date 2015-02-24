#!/usr/bin/Rscript

library(ggplot2)
library(reshape2)
library(getopt)

#get options, using the spec as defined by the enclosed list.
#we read the options from the default: commandArgs(TRUE).
spec = matrix(c(
  'help', 'h', 0, "logical",
  'path', 'p', 1, "character"
), byrow=TRUE, ncol=4);

opt = getopt(spec);
# if help was asked for print a friendly message
# and exit with a non-zero error code
if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

setwd(opt$path)

data <- read.table("per_base_quality_tile.txt", header=T,sep="\t")

rownames(data) <- data[,1]
data <- data[,2:ncol(data)]

data <- as.data.frame(t(apply(data, 1, function(x) { x / sum(x) } )))

names(data) <- gsub(names(data), pattern="X", replacement="")
names(data) <- as.numeric(as.character(names(data)))
data$base <- rownames(data)
data$base <- as.numeric(as.character(data$base))
mdata <- melt(data, id.vars="base")
mdata$variable <- as.numeric(as.character(mdata$variable))
names(mdata) <- c("base", "quality", "value")

mean <- read.table("per_base_quality.txt", header=T, sep="\t", colClasses=c("numeric", "numeric"))

p <- ggplot(mdata) + 
    geom_tile(aes(x=base,y=quality,fill=value)) +
    geom_line(data=mean, aes(x=base,y=mean)) +
    scale_fill_gradient2(low="white", high="red", space="Lab", na.value = "grey50", guide="colorbar")

ggsave(filename="per_base_quality.pdf", plot=p, width=8, height=6)

