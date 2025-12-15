library(ggplot2)
library(dplyr)
library(gridExtra)

base_dir = "/Volumes/gillandersw/Active/Project_0001_Clinical_Trials/pipeline_tests/hcc1395/pvactools_releases/"

#data versions:
data_versions = c("7.0.0a14", "7.0.0a18", "7.0.0a18_normalize_percentile_length_agnostic")

for (a in seq_along(data_versions)){
  data_version = data_versions[a]
  
  inputs_dir = paste(base_dir, data_version, "/", sep="")
  outputs_dir = paste(base_dir, data_version, "/plots/", sep="")
    
  #Set directory to load data
  setwd(inputs_dir)
  dir()
  
  #Load all data
  all_epitopes_standard = read.table(file="result_standard_percentiles/MHC_Class_I/HCC1395_TUMOR_DNA.MHC_I.all_epitopes.tsv", header=T, sep="\t")
  all_epitopes_normalized = read.table(file="result_normalized_percentiles/MHC_Class_I/HCC1395_TUMOR_DNA.MHC_I.all_epitopes.tsv", header=T, sep="\t")
  dim(all_epitopes_standard)
  
  #Create complete dataframe with all alleles but make unique based on peptide-allele combinations
  all_epitopes_standard$allele.peptide = paste(all_epitopes_standard$HLA.Allele,all_epitopes_standard$MT.Epitope.Seq,sep="_")
  all_epitopes_normalized$allele.peptide = paste(all_epitopes_normalized$HLA.Allele,all_epitopes_normalized$MT.Epitope.Seq,sep="_")
  
  all_epitopes_standard_unique2 <- all_epitopes_standard %>% distinct(allele.peptide, .keep_all = TRUE)
  all_epitopes_normalized_unique2 <- all_epitopes_normalized %>% distinct(allele.peptide, .keep_all = TRUE)
  dim(all_epitopes_standard_unique2)
  dim(all_epitopes_normalized_unique2)
  
  #Set directory to save plots
  setwd(outputs_dir)
  dir()
  
  #Create a function that produces visuals for a given predictor metric, comparing the two data frames (standard vs normalized)
  compare_percentiles_plot = function(df1, df2, data_column_name, x_label, y_label, allele){
  
    df <- data.frame(
      standard = df1[, data_column_name],
      normalized = df2[, data_column_name],
      peptide_length = df2[, "Peptide.Length"]
    )
  
    fit <- lm(normalized ~ standard, data = df)
    r2 <- summary(fit)$r.squared
    r2_label <- paste0("R² = ", round(r2, 3))
    peptide_count = dim(df)[1]
    title_text = paste(data_column_name, " (n=",  peptide_count, ") - " , allele, sep="")
    
    percentiles_plot = ggplot(df, aes(standard, normalized)) +
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
      labs(
        title = title_text,
        x = x_label,
        y = y_label,
        color = "Peptide Length"
      ) + 
      coord_equal()
    return(percentiles_plot)
  }
  
  distributions_plot = function(df1, df2, column_name){
    df <- data.frame(
      standard = df1[, column_name],
      normalized = df2[, column_name],
      peptide_length = df2[, "Peptide.Length"]
    )
    title_text = paste("Distribution of Scores (", column_name, ")", sep="")
    dist_plot = ggplot(df, aes(x = standard)) +
      geom_histogram(aes(y = after_stat(density)), bins = 50, alpha = 0.4) +
      geom_density(linewidth = 1.2) +
      labs(title = title_text,
           x = "Score",
           y = "Density") +
      theme_bw()
      return(dist_plot)
  }
  
  distributions_by_length_plot = function(df1, column_name, datatype){
    df <- data.frame(
      value = df1[, column_name],
      peptide_length = as.factor(df1[, "Peptide.Length"])
    )
    title_text = paste(column_name, " (",  datatype, ")", sep="")
    dist_plot = ggplot(df, aes(x = value)) +
      geom_histogram(aes(y = after_stat(density), fill = peptide_length), bins = 50, alpha = 0.4) +
      geom_density(linewidth = 1.2) +
      labs(title = title_text,
           x = column_name,
           y = "Density") +
      facet_wrap(~ peptide_length, scales = "free") +
      scale_fill_discrete() +
      theme_bw()
    return(dist_plot)
  }
  
  distributions_by_allele_plot = function(df1, column_name){
    df <- data.frame(
      value = df1[, column_name],
      allele = as.factor(df1[, "HLA.Allele"])
    )
    title_text = paste(column_name, sep="")
    allele_plot = ggplot(df, aes(x = value)) +
      geom_histogram(aes(y = after_stat(density), fill = allele), bins = 50, alpha = 0.4) +
      geom_density(linewidth = 1.2) +
      labs(title = title_text,
           x = column_name,
           y = "Density") +
      facet_wrap(~ allele, scales = "free") +
      scale_fill_brewer(palette = "Dark2") +
      theme_bw()
    return(allele_plot)
  }
  
  #Set some global axis labels
  x_label_p = "Percentile provided natively by each tool"
  y_label_p = "Percentile normalized by pVACtools"
  x_label_s = "Score from pVACtools run WITHOUT normalized percentile"
  y_label_s = "Score from pVACtools run WITH normalized percentile"

  monitor_ratio <- 3840 / 2160
  w <- 20
  h <- w / monitor_ratio

  #Aggregated percentile scores (combining different sets of algorithms)
  percentiles_plot_median = compare_percentiles_plot(all_epitopes_standard_unique2, all_epitopes_normalized_unique2, "Median.MT.Percentile", x_label_p, y_label_p, "all alleles")
  filename = "percentiles_plot_median.pdf"
  pdf(file=filename, width = w, height = h)
  print(percentiles_plot_median)
  dev.off()

  percentiles_plot_median_ic50 = compare_percentiles_plot(all_epitopes_standard_unique2, all_epitopes_normalized_unique2, "Median.MT.IC50.Percentile", x_label_p, y_label_p, "all alleles")
  filename = "percentiles_plot_median_ic50.pdf"
  pdf(file=filename, width = w, height = h)
  print(percentiles_plot_median_ic50)
  dev.off()
  
  percentiles_plot_median_presentation = compare_percentiles_plot(all_epitopes_standard_unique2, all_epitopes_normalized_unique2, "Median.MT.Presentation.Percentile", x_label_p, y_label_p, "all alleles")
  filename = "percentiles_plot_median_presentation.pdf"
  pdf(file=filename, width = w, height = h)
  print(percentiles_plot_median_presentation)
  dev.off()
  
  percentiles_plot_median_immunogenicity = compare_percentiles_plot(all_epitopes_standard_unique2, all_epitopes_normalized_unique2, "Median.MT.Immunogenicity.Percentile", x_label_p, y_label_p, "all alleles")
  filename = "percentiles_plot_median_immunogenicity.pdf"
  pdf(file=filename, width = w, height = h)
  print(percentiles_plot_median_immunogenicity)
  dev.off()
  
  #Limit analysis to a specific allele: "HLA-A*29:02" "HLA-B*45:01" "HLA-B*82:02" "HLA-C*06:02"
  allele_list = unique(all_epitopes_standard$HLA.Allele)
  
  percentile_columns = c("MHCflurryEL.Presentation.MT.Percentile", 
                         "MHCflurry.MT.Percentile",
                         "MHCnuggetsI.MT.Percentile",
                         "MixMHCpred.MT.Percentile",
                         "PRIME.MT.Percentile",
                         "NetMHC.MT.Percentile",
                         "NetMHCcons.MT.Percentile",
                         "NetMHCpan.MT.Percentile",
                         "NetMHCpanEL.MT.Percentile",
                         "PickPocket.MT.Percentile",
                         "SMM.MT.Percentile",
                         "SMMPMBEC.MT.Percentile"
  )
  length(percentile_columns)
  
  score_columns = c("MHCflurryEL.Presentation.MT.Score",
                    "MHCflurry.MT.IC50.Score",
                    "MHCnuggetsI.MT.IC50.Score",
                    "MixMHCpred.MT.Binding.Score",
                    "PRIME.MT.Immunogenicity.Score",
                    "NetMHC.MT.IC50.Score",
                    "NetMHCcons.MT.IC50.Score",
                    "NetMHCpan.MT.IC50.Score",
                    "NetMHCpanEL.MT.Presentation.Score",
                    "PickPocket.MT.IC50.Score",
                    "SMM.MT.IC50.Score",
                    "SMMPMBEC.MT.IC50.Score"
  )
  length(score_columns)

  for (i in seq_along(allele_list)){
    allele <- allele_list[i]
  
    i = which(all_epitopes_standard$HLA.Allele == allele)
    all_epitopes_standard_one_allele = all_epitopes_standard[i,]
    i = which(all_epitopes_normalized$HLA.Allele == allele)
    all_epitopes_normalized_one_allele = all_epitopes_normalized[i,]
    dim(all_epitopes_standard_one_allele)
    
    #Remove duplicate values (e.g. different transcripts that give rise to the exact same peptide prediction data)
    all_epitopes_standard_unique <- all_epitopes_standard_one_allele %>% distinct(MT.Epitope.Seq, .keep_all = TRUE)
    all_epitopes_normalized_unique <- all_epitopes_normalized_one_allele %>% distinct(MT.Epitope.Seq, .keep_all = TRUE)
    dim(all_epitopes_standard_unique)
    dim(all_epitopes_normalized_unique)
    
    for (j in seq_along(percentile_columns)){
      percentile_column <- percentile_columns[j]
      score_column <- score_columns[j]
      print(paste("Allele:", allele, "Percentile:", percentile_column, " Score:", score_column))
   
      non_na_count_standard = length(which(!is.na(all_epitopes_standard_unique[,score_column])))
      if (non_na_count_standard == 0) {
        print("  Only NA values found for this combination - skipping")
        next   
      }
      
      #Percentile scores for individual algorithms that have native percentile scores we can compare the normalized percentiles to
      percentiles_plot = compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, percentile_column, x_label_p, y_label_p, allele)
      scores_plot = compare_percentiles_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, score_column, x_label_s, y_label_s, allele)
      score_dist_plot = distributions_plot(all_epitopes_standard_unique, all_epitopes_normalized_unique, score_column)
      percentile_dist_standard = distributions_by_length_plot(all_epitopes_standard_unique, percentile_column, "Native From Tool")
      percentile_dist_normalized = distributions_by_length_plot(all_epitopes_normalized_unique, percentile_column, "Normalized")
      alleles_plot = distributions_by_allele_plot(all_epitopes_standard_unique2, score_column)
      
      allele_clean <- gsub("[^\\x20-\\x7E]", "_", allele)
      allele_clean2 <- gsub(":", "_", allele_clean)
      filename = paste(allele_clean2, "_", percentile_column, ".pdf", sep="")
      pdf(file=filename, width = w, height = h)
      grid.arrange(scores_plot, score_dist_plot, alleles_plot, percentile_dist_standard, percentile_dist_normalized, percentiles_plot, nrow = 2, ncol = 3)
      dev.off()
    }
  }
}

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


