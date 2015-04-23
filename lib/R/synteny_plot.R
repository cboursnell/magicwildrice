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

SR <- subset(data, species_a=="sativa" & species_b=="rufipogon")

p <- ggplot(SR, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave(filename="SR_synteny.pdf", plot=p, width=24, height=24)

SG <- subset(data, species_a=="sativa" & species_b=="glaberrima")

p <- ggplot(SG, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave(filename="SG_synteny.pdf", plot=p, width=24, height=24)

RG <- subset(data, species_a=="rufipogon" & species_b=="glaberrima")

p <- ggplot(RG, aes(x=position_a, y=position_b)) +
  geom_point(alpha=0.1, size=1) +
  facet_grid(chrom_a ~ chrom_b, scales="free", space="free", shrink=TRUE) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggsave(filename="RG_synteny.pdf", plot=p, width=24, height=24)