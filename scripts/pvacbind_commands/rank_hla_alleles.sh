cat HLA-PrioritizationList.txt | perl -ne 'chomp; @l=split("\t",$_); if ($_ =~ /^allele/){print "rank\tallele_pvacseq\t$_\n"}else{$rank=$l[2]+$l[6]+$l[7]+$l[8]+$l[9]+$l[10]+$l[11]+$l[12]+$l[13]; print "$rank\tHLA\-$l[0]\t$_\n"}' > HLA-PrioritizationList-Ranked.tsv

cat HLA-PrioritizationList-Ranked.tsv | cut -f 1-2 | sort -n -r | grep -v rank | cut -f 2 > ranked_classI_alleles_with_data.txt

awk 'NR==FNR {rank[$0]=++i; next} 
     { if ($0 in rank) print rank[$0], $0; else print 999999, NR, $0 }' \
    ranked_classI_alleles_with_data.txt pvacbind_valid_classI_alleles.txt \
  | sort -n | cut -d' ' -f2- > pvacbind_valid_classI_alleles_ordered.txt

cat pvacbind_valid_classI_alleles_ordered.txt | perl -ne 'chomp; if ($_ =~ /(HLA\-.*)/){print "$1\n"}' > pvacbind_valid_classI_alleles_ordered.txt2
mv pvacbind_valid_classI_alleles_ordered.txt2 pvacbind_valid_classI_alleles_ordered.txt

head -n 3 pvacbind_valid_classI_alleles_ordered.txt > pvacbind_valid_classI_alleles_ordered_first-3.txt

