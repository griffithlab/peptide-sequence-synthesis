awk '/^>/{sub(/.*_/, ">", $0)}1' 1K_Peptides/reference_8mer_1K_mutated_1x.fasta > tmp && mv tmp 1K_Peptides/reference_8mer_1K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1K_Peptides/reference_9mer_1K_mutated_1x.fasta > tmp && mv tmp 1K_Peptides/reference_9mer_1K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1K_Peptides/reference_10mer_1K_mutated_1x.fasta > tmp && mv tmp 1K_Peptides/reference_10mer_1K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1K_Peptides/reference_11mer_1K_mutated_1x.fasta > tmp && mv tmp 1K_Peptides/reference_11mer_1K_mutated_1x.fasta

awk '/^>/{sub(/.*_/, ">", $0)}1' 100K_Peptides/reference_8mer_100K_mutated_1x.fasta > tmp && mv tmp 100K_Peptides/reference_8mer_100K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 100K_Peptides/reference_9mer_100K_mutated_1x.fasta > tmp && mv tmp 100K_Peptides/reference_9mer_100K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 100K_Peptides/reference_10mer_100K_mutated_1x.fasta > tmp && mv tmp 100K_Peptides/reference_10mer_100K_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 100K_Peptides/reference_11mer_100K_mutated_1x.fasta > tmp && mv tmp 100K_Peptides/reference_11mer_100K_mutated_1x.fasta

awk '/^>/{sub(/.*_/, ">", $0)}1' 1M_Peptides/reference_8mer_1M_mutated_1x.fasta > tmp && mv tmp 1M_Peptides/reference_8mer_1M_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1M_Peptides/reference_9mer_1M_mutated_1x.fasta > tmp && mv tmp 1M_Peptides/reference_9mer_1M_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1M_Peptides/reference_10mer_1M_mutated_1x.fasta > tmp && mv tmp 1M_Peptides/reference_10mer_1M_mutated_1x.fasta
awk '/^>/{sub(/.*_/, ">", $0)}1' 1M_Peptides/reference_11mer_1M_mutated_1x.fasta > tmp && mv tmp 1M_Peptides/reference_11mer_1M_mutated_1x.fasta

