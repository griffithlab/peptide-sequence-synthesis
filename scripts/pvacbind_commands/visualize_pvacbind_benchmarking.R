#Visualize run time statistics for pvacbind percentiles scores jobs
#Account for different numbers of CPUs used for each job

library(ggplot2)
library(dplyr)
library(scales)

#Example input data file:
#/Volumes/mgriffit/Active/immune/pvactools_percentiles/run_stats_100Kpeptides_v7.0.0a8_first-3-alleles.tsv

infile = "/Volumes/mgriffit/Active/immune/pvactools_percentiles/run_stats_100Kpeptides_v7.0.0a8_first-3-alleles.tsv"

rundata = read.table(infile, sep="\t", header=T)
rundata = rundata %>% rename(Algorithm = ALGORITHM)
rundata = rundata %>% rename(Length = LENGTH)
rundata = rundata %>% rename(CPUs = CPUS)
rundata = rundata %>% rename(FastaSize = FASTA_SIZE)
rundata$Length <- as.factor(rundata$Length)

rundata$minutes = rundata$SECONDS/60
rundata$cpu_minutes = (rundata$SECONDS * rundata$CPUs)/60

#plot for actual run time (not adjusted for CPU count)
p = ggplot(rundata, aes(x = Algorithm, y = minutes)) +
  # Violin plots
  geom_violin(trim = FALSE, fill = "gray90", color = "gray70") +
  # Individual data points (with jitter for visibility)
  geom_jitter(aes(color=Length), width = 0.2, size = 2, alpha = 0.5) +
  # Optional: overlay median or mean
  stat_summary(fun = median, geom = "point", shape = 23, size = 1, fill = "white") +
  scale_y_log10(breaks=c(1,5,10,30,60,90,100,120,150)) +
  theme_bw(base_size = 14) + 
  labs(
    x = "Algorithm",
    y = "Runtime log10(minutes)",
    color = "Length"
  ) +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

p + 
  geom_text(
    data = rundata,
    aes(x = Algorithm, y = 1.25, label = paste0(MEM, " GB")),
    color = "black",
    size = 4
  ) +
  geom_text(
    data = rundata,
    aes(x = Algorithm, y = 1.5, label = paste0(CPUs, " cpu")),
    color = "black",
    size = 4
  ) +
  geom_text(
    data = rundata,
    aes(x = Algorithm, y = 1.75, label = FastaSize),
    color = "black",
    size = 4
  ) +
  coord_cartesian(clip = "off")  # allow text outside plot area

#plot for run time adjusted for CPU count


