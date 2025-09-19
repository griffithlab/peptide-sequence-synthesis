#!/bin/bash

#inputs
PEPTIDE_SET="1K"
ALLELE_SET="first-3"
PVACTOOLS_VERSION="5.5.2"
WORKING_BASE=/storage1/fs1/mgriffit/Active/immune/pvactools_percentiles
RESULTS_BASE=$WORKING_BASE/pvacbind_results
SCRATCH_BASE=/scratch1/fs1/mgriffit/pvacbind_results
FASTA_BASE=$WORKING_BASE/peptide-sequence-synthesis/data/${PEPTIDE_SET}_Peptides
ALLELES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/pvacbind_valid_classI_alleles_ordered_${ALLELE_SET}.txt
SCORE_NAMES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/classI_score_names_${PVACTOOLS_VERSION}.txt
ALG_NAMES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/classI_algorithm_names_${PVACTOOLS_VERSION}.txt
ALG_RESOURCES_FILE=$WORKING_BASE/peptide-sequence-synthesis/scripts/pvacbind_commands/classI_algorithm_resources_${PVACTOOLS_VERSION}.txt

#outputs
RUN_COMMAND_FILE="${WORKING_BASE}/run_commands_${PEPTIDE_SET}peptides_v${PVACTOOLS_VERSION}_${ALLELE_SET}-alleles.sh"
RUN_NAME_FILE="${WORKING_BASE}/run_names_${PEPTIDE_SET}peptides_v${PVACTOOLS_VERSION}_${ALLELE_SET}-alleles.txt"

#other parameters
LENGTHS=(8 9 10 11)
COMPUTE_GROUP="compute-oncology"
JOB_GROUP="/mgriffit/perc"
QUEUES=(general siteman oncology)
QUEUE_COUNT=${#QUEUES[@]}
COUNTER=0 

if [ ! -f "$ALLELES_FILE" ]; then
    echo "Error: Input file $ALLELES_FILE not found. Exiting."
    exit 1
fi

if [ ! -f "$SCORE_NAMES_FILE" ]; then
    echo "Error: Input file $SCORE_NAMES_FILE not found. Exiting."
    exit 1
fi

#Initialize two files to hold the LSF commands and unique Run names:
> $RUN_COMMAND_FILE
> $RUN_NAME_FILE

# Read HLA allele name into an array from the input file
mapfile -t HLA_ALLELES < "$ALLELES_FILE"

# Read algorithms to be used into an array from the input file
mapfile -t ALGORITHMS < "$ALG_NAMES_FILE"

# Read in algorithm name link to resource use requirements for each. Skip header line
declare -A MEM_REQ
declare -A CPU_REQ
while read -r ALGO MEM CPU; do
    MEM_REQ[$ALGO]=$MEM
    CPU_REQ[$ALGO]=$CPU
done < <(tail -n +2 $ALG_RESOURCES_FILE)

mkdir -p $RESULTS_BASE/${PVACTOOLS_VERSION}
mkdir -p $SCRATCH_BASE/${PVACTOOLS_VERSION}

# Loop through arrays
for HLA in "${HLA_ALLELES[@]}"; do
  for LEN in "${LENGTHS[@]}"; do
    PEPTIDE_SET_FILE=$FASTA_BASE/reference_${LEN}mer_${PEPTIDE_SET}_mutated_1x.fasta
    for ALGO in "${ALGORITHMS[@]}"; do
      MEM=${MEM_REQ[$ALGO]}
      MEM_SHORT=$(( MEM * 1000 ))
      MEM_LONG=$(( MEM * 1000000 ))
      CPUS=${CPU_REQ[$ALGO]}
      QUEUE=${QUEUES[$(( COUNTER % QUEUE_COUNT ))]}
      ((COUNTER++))

      HLA_NAME="${HLA//\*/_}"
      HLA_NAME="${HLA_NAME//\:/_}"
      RUN_NAME=LEN-${LEN}_${HLA_NAME}_ALG-${ALGO}
      SCRATCH_OUTDIR=${SCRATCH_BASE}/${PVACTOOLS_VERSION}/${LEN}/${ALGO}/${RUN_NAME}
      FINAL_OUTDIR=${RESULTS_BASE}/${PVACTOOLS_VERSION}/${LEN}/${ALGO}/${RUN_NAME}
      SCRIPT_FILE=${FINAL_OUTDIR}/${RUN_NAME}.sh
      STATUS_FILE_RUNNING="${FINAL_OUTDIR}/${RUN_NAME}.status.running"
      STATUS_FILE_COMPLETED="${FINAL_OUTDIR}/${RUN_NAME}.status.completed"

      #If the dir already exists, leave it untouched an continue on
      if [ -d "$FINAL_OUTDIR" ]; then
	  echo "Final output dir for run $RUN_NAME already exists ... skipping"
	  continue
      fi

      mkdir -p $FINAL_OUTDIR

      #Create the bash script file to run pVACbind for a single HLA allele, length and algorithm combination
      #create a status file to indicate this job is running
      echo "SECONDS=0" >> $SCRIPT_FILE
      echo "echo \"Run script started for $RUN_NAME\" > $STATUS_FILE_RUNNING" >> $SCRIPT_FILE
      echo "set -euo pipefail" > $SCRIPT_FILE
      echo "date" >> $SCRIPT_FILE
      echo "echo \"Using pvactools version: $PVACTOOLS_VERSION\"" >> $SCRIPT_FILE
      echo "echo \"Generating predictions for $RUN_NAME\"" >> $SCRIPT_FILE
      echo "mkdir -p $SCRATCH_OUTDIR" >> $SCRIPT_FILE
      echo "pvacbind run $PEPTIDE_SET_FILE $RUN_NAME $HLA $ALGO $SCRATCH_OUTDIR --class-i-epitope-length $LEN --n-threads 8 --iedb-install-directory /opt/iedb --fasta-size 10000" >> $SCRIPT_FILE

      #cut out only the score columns for relevant algorithms present in this ouput
      echo mapfile -t classI_score_names \< $SCORE_NAMES_FILE >> $SCRIPT_FILE
      echo "header=\$(head -n 1 $SCRATCH_OUTDIR/MHC_Class_I/${RUN_NAME}.all_epitopes.tsv)" >> $SCRIPT_FILE
      echo positions=\(\) >> $SCRIPT_FILE
      echo i=1 >> $SCRIPT_FILE
      echo "while IFS= read -r col; do" >> $SCRIPT_FILE
      echo "    for name in \"\${classI_score_names[@]}\"; do" >> $SCRIPT_FILE
      echo "       if [[ \"\$col\" == \"\$name\" ]]; then" >> $SCRIPT_FILE
      echo "            positions+=(\"\$i\")" >> $SCRIPT_FILE
      echo "        fi" >> $SCRIPT_FILE
      echo "    done" >> $SCRIPT_FILE
      echo "    ((i++))" >> $SCRIPT_FILE
      echo "done < <(echo \"\$header\" | tr '\t' '\n')" >> $SCRIPT_FILE

      echo "cut_cols=\$(IFS=, ; echo \"\${positions[*]}\")" >> $SCRIPT_FILE
      echo "cut -f \${cut_cols} $SCRATCH_OUTDIR/MHC_Class_I/${RUN_NAME}.all_epitopes.tsv | gzip > $FINAL_OUTDIR/${RUN_NAME}.scores.tsv.gz" >> $SCRIPT_FILE

      #save the pvacbind log file, remove the scratch dir, log a completion message and ending date, remove the running status file
      echo cp $SCRATCH_OUTDIR/MHC_Class_I/log/inputs.yml $FINAL_OUTDIR/pvacseq_inputs_classI.yml >> $SCRIPT_FILE
      echo rm -fr $SCRATCH_OUTDIR >> $SCRIPT_FILE
      echo "echo \"Completed run for $RUN_NAME\"" >> $SCRIPT_FILE
      echo date >> $SCRIPT_FILE
      echo "rm -f $STATUS_FILE_RUNNING" >> $SCRIPT_FILE

      #output other basic information about this run (source of inputs, resources used, etc.) so that it gets saved in stdout
      echo "echo -e \"\nRun info:\nRUN_NAME: $RUN_NAME\nPVACTOOLS_VERSION: $PVACTOOLS_VERSION\nALLELES_FILE: $ALLELES_FILE\nPEPTIDE_SET_FILE: $PEPTIDE_SET_FILE\nMEM: $MEM\nCPUS: $CPUS\"" >> $SCRIPT_FILE

      #report on how long this run took
      echo "elapsed=\$SECONDS" >> $SCRIPT_FILE
      echo "days=\$(( elapsed / 86400 ))" >> $SCRIPT_FILE
      echo "hours=\$(( (elapsed % 86400) / 3600 ))" >> $SCRIPT_FILE
      echo "minutes=\$(( (elapsed % 3600) / 60 ))" >> $SCRIPT_FILE
      echo "seconds=\$(( elapsed % 60 ))" >> $SCRIPT_FILE
      echo "echo \"Elapsed: \${days}d \${hours}h \${minutes}m \${seconds}s\"" >> $SCRIPT_FILE
      echo "echo \"Run took \$SECONDS seconds to complete\"" >> $SCRIPT_FILE

      #create a status file to indicate the run succeeded
      echo "echo \"Run script complete for $RUN_NAME\" > $STATUS_FILE_COMPLETED" >> $SCRIPT_FILE

      #Create the bsub command to run this script on the cluster
      echo -e "LSF_DOCKER_PRESERVE_ENVIRONMENT=false bsub -M $MEM_LONG -G $COMPUTE_GROUP -n $CPUS -R 'select[mem>$MEM_SHORT] rusage[mem=$MEM_SHORT]' -q $QUEUE -g $JOB_GROUP -a 'docker(griffithlab/pvactools:$PVACTOOLS_VERSION)' -oo $FINAL_OUTDIR/pvacbind.stdout -eo $FINAL_OUTDIR/pvacbind.stderr /bin/bash $SCRIPT_FILE" >> $RUN_COMMAND_FILE
      echo $RUN_NAME >> $RUN_NAME_FILE
    done
  done
done

echo "Wrote all LSF commands to $RUN_COMMAND_FILE"
echo "Wrote a corresponding list of run names to $RUN_NAME_FILE"

