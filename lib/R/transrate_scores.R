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

idba_data <- read.table(file="idba_contigs/transrate_idba_contigs.fa_contigs.csv", sep=",", header=T, colClasses=c("character", rep("numeric", 18) ) )
soap_data <- read.table(file="soap_contigs/transrate_soap_contigs.fa_contigs.csv", sep=",", header=T, colClasses=c("character", rep("numeric", 18) ) )
oases_data <- read.table(file="oases_contigs/transrate_oases_contigs.fa_contigs.csv", sep=",", header=T, colClasses=c("character", rep("numeric", 18) ) )
trin_data <- read.table(file="trinity_contigs/transrate_trinity_contigs.fa_contigs.csv", sep=",", header=T, colClasses=c("character", rep("numeric", 18) ) )
sga_data <- read.table(file="sga_contigs/transrate_sga_contigs.fa_contigs.csv", sep=",", header=T, colClasses=c("character", rep("numeric", 18) ) )

idba_data$assembler <- "idba"
soap_data$assembler <- "soap"
oases_data$assembler <- "oases"
trin_data$assembler <- "trinity"
sga_data$assembler <- "sga"
data <- rbind(idba_data, soap_data)
data <- rbind(data, oases_data)
data <- rbind(data, trin_data)
data <- rbind(data, sga_data)

p<-ggplot(data, aes(x=score)) +
  geom_histogram(binwidth=0.05) +
  facet_grid(assembler ~ .)

ggsave(filename="transrate_scores.pdf", plot=p, width=8, height=14)