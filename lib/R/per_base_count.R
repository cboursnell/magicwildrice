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

#print("path:")
#print(opt$path)
setwd(opt$path)

data <- read.table("per_base_composition.txt", header=T,sep="\t",colClasses=c(rep("numeric",5)))

rownames(data) <- data[,1]
data <- data[,2:ncol(data)]

data <- as.data.frame(t(apply(data, 1, function(x) { x / sum(x) } )))

data$base <- rownames(data)
data$base <- as.numeric(as.character(data$base))

mdata <- melt(data, id.vars="base")

p <- ggplot(mdata, aes(x=base, y=value, group=variable)) +
        geom_line(aes(colour=variable))
ggsave(filename="per_base_count.pdf", plot=p, width=8, height=6)
