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

data <- read.table(file="synteny_data.csv", sep="\t", colClasses=c("factor", "character", "numeric", "factor", "character", "numeric"))
names(data) <- c("species_a", "chrom_a", "position_a","species_b", "chrom_b", "position_b")
#summary(data)

SR <- subset(data, species_a=="Oryza Sativa" & species_b=="Oryza Rufipogon")

p <- ggplot(SR, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE)

ggsave(filename="SR_synteny.pdf", plot=p, width=24, height=28)


SG <- subset(data, species_a=="Oryza Sativa" & species_b=="Oryza Glaberrima")

p <- ggplot(SG, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE)

ggsave(filename="SG_synteny.pdf", plot=p, width=24, height=28)


RG <- subset(data, species_a=="Oryza Rufipogon" & species_b=="Oryza Glaberrima")

p <- ggplot(RG, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE)

ggsave(filename="RG_synteny.pdf", plot=p, width=24, height=28)