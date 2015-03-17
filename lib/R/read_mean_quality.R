#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)
library(getopt)
library(grid)

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

data <- read.table("read_mean_quality.txt", header=T,sep="\t")

p<-ggplot(data, aes(x = mean)) +
  geom_histogram(binwidth=1) +
  ggtitle("Read Mean Quality") +
  theme(panel.background = element_rect(fill="grey90"),
        panel.grid.minor = element_line(colour="grey80"),
        panel.grid.major = element_line(colour="grey80"),
        axis.ticks  = element_line(colour="grey50"),
        axis.ticks.length  = unit(.35, "cm"),
        axis.text.x = element_text(size = unit(16, "picas")),
        axis.text.y = element_text(size = unit(16, "picas")),
        axis.line   = element_line(colour="grey50"),
        axis.line.x = element_line(colour="grey50"),
        axis.line.y = element_line(colour="grey50"),
        plot.margin = unit(c(0.5,1,1,0.5),"cm"))

ggsave(filename="mean_read_quality.pdf", plot=p, width=8, height=6)