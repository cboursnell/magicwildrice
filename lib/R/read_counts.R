#!/usr/bin/env Rscript

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

data <- read.table("read_counts.txt", header=T,sep="\t")

p<-ggplot(data, aes(x = file, y = count, fill = file)) +
  geom_bar(stat = "identity", position = "identity") +
  ggtitle("Read Counts") +
  guides(fill=FALSE) +
  labs(x = "File") +
  theme(axis.text.x = element_text(size  = 10, hjust = 1, vjust = 1)) +
  #scale_y_continuous(breaks=seq(0,10000,by=5000)) +
  geom_text(aes(x = file, y = count + 400, label = format(data$count, digits=2)),
            hjust=0.5, size=3, color=rgb(100,100,100, maxColorValue=255)) +
  coord_flip() +
  theme(panel.background = element_blank(),
      panel.grid.minor = element_blank(),
      #axis.ticks  = element_blank(),
      axis.line   = element_line(colour=NA),
      axis.line.x = element_line(colour="grey50"),
      axis.line.y = element_line(colour="grey80"))

ggsave(filename="read_counts.pdf", plot=p, width=8, height=6)