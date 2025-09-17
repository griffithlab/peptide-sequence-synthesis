#!/bin/bash

PEPTIDE_SET="1K"
PVACTOOLS_VERSION="5.5.2"
WORKING_BASE=/storage1/fs1/mgriffit/Active/immune/pvactools_percentiles
RESULTS_BASE=$WORKING_BASE/pvacbind_results/$PVACTOOLS_VERSION
SCRATCH_BASE=/scratch1/fs1/mgriffit/pvacbind_results/$PVACTOOLS_VERSION
FASTA_BASE=$WORKING_BASE/peptide-sequence-synthesis/data/${PEPTIDE_SET}_Peptides
ALLELES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/pvacbind_valid_classI_alleles_ordered_first-3.txt
SCORE_NAMES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/classI_score_names_5.5.2.txt
RUN_COMMAND_FILE="${WORKING_BASE}/run_commands_${PEPTIDE_SET}_${PVACTOOLS_VERSION}.sh"
RUN_NAME_FILE="${WORKING_BASE}/run_names_${PEPTIDE_SET}_${PVACTOOLS_VERSION}.txt"

#Initialize two files to hold the LSF commands and unique Run names:
> $RUN_COMMAND_FILE
> $RUN_NAME_FILE

# Read alleles file into array
mapfile -t HLA_ALLELES < "$ALLELES_FILE"
mapfile -t classI_score_names < $SCORE_NAMES_FILE

mkdir -p $RESULTS_BASE
mkdir -p $SCRATCH_BASE

# Define lengths array
LENGTHS=(8 9 10 11)

# Loop through arrays
for HLA in "${HLA_ALLELES[@]}"; do
  for LEN in "${LENGTHS[@]}"; do
    HLA_NAME="${HLA//\*/_}"
    HLA_NAME="${HLA_NAME//\:/_}"
    RUN_NAME=${LEN}_${HLA_NAME}_AllClassI
    SCRATCH_OUTDIR=${SCRATCH_BASE}/${LEN}/${RUN_NAME}
    FINAL_OUTDIR=${RESULTS_BASE}/${LEN}/${RUN_NAME}
    SCRIPT_FILE=${FINAL_OUTDIR}/${RUN_NAME}.sh
    STATUS_FILE="${FINAL_OUTDIR}/${RUN_NAME}.status"

    mkdir -p $FINAL_OUTDIR

    #Create the bash script file for a single HLA-Allele and Length Combination
    echo "set -euo pipefail" > $SCRIPT_FILE
    echo "date" >> $SCRIPT_FILE
    echo "echo \"Using pvactools version: $PVACTOOLS_VERSION\"" >> $SCRIPT_FILE
    echo "echo \"Generating predictions for $RUN_NAME\"" >> $SCRIPT_FILE
    echo "mkdir -p $SCRATCH_OUTDIR" >> $SCRIPT_FILE
    echo "pvacbind run $FASTA_BASE/reference_${LEN}mer_${PEPTIDE_SET}_mutated_1x.fasta $RUN_NAME $HLA all_class_i $SCRATCH_OUTDIR --class-i-epitope-length $LEN --n-threads 8 --iedb-install-directory /opt/iedb --fasta-size 10000" >> $SCRIPT_FILE

    echo "header=\$(head -n 1 $SCRATCH_OUTDIR/MHC_Class_I/${RUN_NAME}.all_epitopes.tsv)" >> $SCRIPT_FILE
    echo positions=\(\) >> $SCRIPT_FILE
    echo i=1 >> $SCRIPT_FILE
    echo "for col in \$(echo \"\$header\" | tr '\t' '\n'); do" >> $SCRIPT_FILE
    echo "    for name in \"\${score_names[@]}\"; do" >> $SCRIPT_FILE
    echo "       if [[ \"\$col\" == \"\$name\" ]]; then" >> $SCRIPT_FILE
    echo "            positions+=(\"\$i\")" >> $SCRIPT_FILE
    echo "        fi" >> $SCRIPT_FILE
    echo "    done" >> $SCRIPT_FILE
    echo "    ((i++))" >> $SCRIPT_FILE
    echo "done" >> $SCRIPT_FILE
    echo "cut_cols=\$(IFS=, ; echo \"\${positions[*]}\")" >> $SCRIPT_FILE

    #echo "cut -f 1,11,12,13,14,16,18,20,22,24,26,28,30,32 $SCRATCH_OUTDIR/MHC_Class_I/${RUN_NAME}.all_epitopes.tsv | gzip > $FINAL_OUTDIR/${RUN_NAME}.scores.tsv.gz" >> $SCRIPT_FILE
    echo "cut -f 1,\${cut_cols} $SCRATCH_OUTDIR/MHC_Class_I/${RUN_NAME}.all_epitopes.tsv | gzip > $FINAL_OUTDIR/${RUN_NAME}.scores.tsv.gz" >> $SCRIPT_FILE

    echo cp $SCRATCH_OUTDIR/MHC_Class_I/log/inputs.yml $FINAL_OUTDIR/pvacseq_inputs_classI.yml >> $SCRIPT_FILE
    echo rm -fr $SCRATCH_OUTDIR >> $SCRIPT_FILE
    echo "echo \"Completed run for $RUN_NAME\"" >> $SCRIPT_FILE
    echo date >> $SCRIPT_FILE
    echo "echo \"Run script complete for $RUN_NAME\" > $STATUS_FILE" >> $SCRIPT_FILE

    #Create the bsub command to run this script on the cluster
    echo -e "LSF_DOCKER_PRESERVE_ENVIRONMENT=false bsub -M 64000000 -G compute-oncology -n 8 -R 'select[mem>64000] rusage[mem=64000]' -q general -g /mgriffit/perc -a 'docker(griffithlab/pvactools:$PVACTOOLS_VERSION)' -oo $FINAL_OUTDIR/pvacbind.stdout -eo $FINAL_OUTDIR/pvacbind.stderr /bin/bash $SCRIPT_FILE" >> $RUN_COMMAND_FILE
    echo $RUN_NAME >> $RUN_NAME_FILE

  done
done

echo "Wrote all LSF commands to $RUN_COMMAND_FILE"
echo "Wrote a corresponding list of run names to $RUN_NAME_FILE"

