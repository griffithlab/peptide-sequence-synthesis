#Visualize run time statistics for pvacbind percentiles scores jobs
library(ggplot2)
library(dplyr)
library(scales)
library(rlang)

#Example input data file:
#/Volumes/mgriffit/Active/immune/pvactools_percentiles/run_stats_100Kpeptides_v7.0.0a8_first-3-alleles.tsv

binding_algorithms = c("MHCflurry", "MHCnuggetsI", "NetMHC", "NetMHCcons", "NetMHCpan", "PickPocket", "SMM", "SMMPMBEC", "MixMHCpred")
presentation_algorithms  = c("BigMHC_EL", "MHCflurryEL", "NetMHCpanEL")
immunogenicity_algorithms = c("BigMHC_IM", "DeepImmuno", "PRIME")

infile = "/Volumes/mgriffit/Active/immune/pvactools_percentiles/run_stats_100Kpeptides_v7.0.0a8_first-3-alleles.tsv"

rundata = read.table(infile, sep="\t", header=T)
rundata = rundata %>% rename(Algorithm = ALGORITHM)
rundata = rundata %>% rename(Length = LENGTH)
rundata = rundata %>% rename(CPUs = CPUS)
rundata = rundata %>% rename(FastaSize = FASTA_SIZE)
rundata$Length <- as.factor(rundata$Length)

#label each row according to the algorithm category
rundata$AlgorithmType = "Binding"
rundata[which(rundata$Algorithm %in% presentation_algorithms), "AlgorithmType"] = "Present"
rundata[which(rundata$Algorithm %in% immunogenicity_algorithms), "AlgorithmType"] = "Immuno"

#convert run times to minuts and normalize by cpu count
rundata$minutes = rundata$SECONDS/60
rundata$cpu_minutes = (rundata$SECONDS * rundata$CPUs)/60

plot_runtime = function(time_col, title_text, ybreaks){
p = ggplot(rundata, aes(x = Algorithm, y = !!ensym(time_col))) +
  # Violin plots
  geom_violin(trim = FALSE, fill = "gray90", color = "gray70") +
  # Individual data points (with jitter for visibility)
  geom_jitter(aes(color=Length), width = 0.2, size = 2, alpha = 0.5) +
  # Optional: overlay median or mean
  stat_summary(fun = median, geom = "point", shape = 23, size = 1, fill = "white") +
  scale_y_log10(breaks=ybreaks) +
  theme_bw(base_size = 14) + 
  labs(
    title = title_text,
    x = "Algorithm",
    y = "Runtime (minutes) (y-axis is log10)",
    color = "Length"
  ) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

p + 
  geom_text(
    data = rundata, aes(x = Algorithm, y = 1.25, label = paste0(MEM, " GB")),
    color = "black", size = 4
  ) +
  geom_text(
    data = rundata, aes(x = Algorithm, y = 1.5, label = paste0(CPUs, " cpu")),
    color = "black", size = 4
  ) +
  geom_text(
    data = rundata, aes(x = Algorithm, y = 1.75, label = FastaSize),
    color = "black", size = 4
  ) +
  geom_text(
    data = rundata, aes(x = Algorithm, y = 2, label = AlgorithmType),
    color = "black", size = 4
  ) +
  coord_cartesian(clip = "off")  # allow text outside plot area
}

#plot for actual run time (not adjusted for CPU count)
title_text = "Algorithm actual run times for 100k peptides"
ybreaks=c(1,5,10,30,60,90,100,120,150,180,240,300,360,420)
plot_runtime(minutes, title_text, ybreaks)

#Plot that accounts for different numbers of CPUs used for each job
title_text = "Algorithm run times for 100k peptides after adjusting for CPU count (CPU*min)"
ybreaks=c(1,5,10,30,60,120,240,360,480,600,1000,2000)
plot_runtime(cpu_minutes, title_text, ybreaks)



