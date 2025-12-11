library(ggplot2)
library(dplyr)

setwd("/Volumes/gillandersw/Active/Project_0001_Clinical_Trials/pipeline_tests/hcc1395/pvactools_releases/7.0.0a14")

dir()

#Load all data
all_epitopes_standard = read.table(file="result_standard_percentiles/MHC_Class_I/HCC1395_TUMOR_DNA.MHC_I.all_epitopes.tsv", header=T, sep="\t")
all_epitopes_normalized = read.table(file="result_normalized_percentiles/MHC_Class_I/HCC1395_TUMOR_DNA.MHC_I.all_epitopes.tsv", header=T, sep="\t")

#Limit analysis to a specific allele:


#
all_epitopes_standard_unique <- all_epitopes_standard %>% distinct(MT.Epitope.Seq, .keep_all = TRUE)
all_epitopes_normalized_unique <- all_epitopes_normalized %>% distinct(MT.Epitope.Seq, .keep_all = TRUE)


#Columns of interest:
#53	Median.MT.Percentile
#54	Median.WT.Percentile
#55	Median.MT.IC50.Percentile
#56	Median.WT.IC50.Percentile
#57	Median.MT.Immunogenicity.Percentile
#58	Median.WT.Immunogenicity.Percentile
#59	Median.MT.Presentation.Percentile
#60	Median.WT.Presentation.Percentile
#63	BigMHC_EL.WT.Percentile
#64	BigMHC_EL.MT.Percentile
#67	BigMHC_IM.WT.Percentile
#68	BigMHC_IM.MT.Percentile
#71	MHCflurryEL.Processing.WT.Percentile
#72	MHCflurryEL.Processing.MT.Percentile
#75	MHCflurryEL.Presentation.WT.Percentile
#76	MHCflurryEL.Presentation.MT.Percentile
#79	MHCflurry.WT.Percentile
#80	MHCflurry.MT.Percentile
#83	MHCnuggetsI.WT.Percentile
#84	MHCnuggetsI.MT.Percentile
#87	MixMHCpred.WT.Percentile
#88	MixMHCpred.MT.Percentile
#91	PRIME.WT.Percentile
#92	PRIME.MT.Percentile
#95	NetMHC.WT.Percentile
#96	NetMHC.MT.Percentile
#99	NetMHCcons.WT.Percentile
#100	NetMHCcons.MT.Percentile
#103	NetMHCpan.WT.Percentile
#104	NetMHCpan.MT.Percentile
#107	NetMHCpanEL.WT.Percentile
#108	NetMHCpanEL.MT.Percentile
#111	PickPocket.WT.Percentile
#112	PickPocket.MT.Percentile
#115	SMM.WT.Percentile
#116	SMM.MT.Percentile
#119	SMMPMBEC.WT.Percentile
#120	SMMPMBEC.MT.Percentile
#124	DeepImmuno.WT.Percentile
#125	DeepImmuno.MT.Percentile

compare_percentiles_plot = function(df1, df2, column_name){

  df <- data.frame(
    standard = df1[, column_name],
    normalized = df2[, column_name],
    peptide_length = df2[, "Peptide.Length"]
  )

  fit <- lm(normalized ~ standard, data = df)
  r2 <- summary(fit)$r.squared
  r2_label <- paste0("R² = ", round(r2, 3))
  title_text = column_name 
  
  ggplot(df, aes(standard, normalized)) +
    stat_density_2d(
      aes(fill = after_stat(level)),
      geom = "polygon",
      contour = TRUE,
      alpha = 0.5
    ) +
    geom_point(aes(color = factor(peptide_length)), size = 1, alpha = 0.75) +
    scale_fill_viridis_c(option = "plasma") +
    scale_color_discrete(
      guide = guide_legend(
        override.aes = list(shape = 16, size = 3, alpha = 1, fill = "white")
      )
    ) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    annotate("text",
             x = -Inf, y = Inf,        # top-left corner
             label = r2_label,
             hjust = -0.5, vjust = +2,
             size = 5) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold")) +
    labs(
      title = title_text,
      x = "Percentile provided natively by each tool",
      y = "Percentile normalized by pVACtools",
      color = "Peptide Length"
    )
}

#Aggregated percentile scores (combining different sets of algorithms)
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "Median.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "Median.MT.IC50.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "Median.MT.Immunogenicity.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "Median.MT.Presentation.Percentile")

#Percentile scores for individual algorithms that have native percentile scores we can compare the normalized percentiles to
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "MHCflurryEL.Presentation.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "MHCflurry.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "MHCnuggetsI.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "MixMHCpred.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "PRIME.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "NetMHC.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "NetMHCcons.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "NetMHCpan.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "NetMHCpanEL.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "PickPocket.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "SMM.MT.Percentile")
compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, "SMMPMBEC.MT.Percentile")

