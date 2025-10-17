#!/usr/bin/env bash
# Usage: ./summarize_pvacbind_jobs.sh <run_name_file> <base_directory>

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Check inputs
if [[ $# -ne 4 ]]; then
  echo -e "\nUsage: $0 <run_name_file> <base_directory> <stats_tsv_out_file> <final_results_directory>" >&2
  echo -e "\ne.g.\n\n./peptide-sequence-synthesis/scripts/pvacbind_commands/summarize_pvacbind_jobs.sh run_names_100Kpeptides_v7.0.0a8_first-3-alleles.txt ./pvacbind_results/7.0.0a8 run_stats_100Kpeptides_v7.0.0a8_first-3-alleles.tsv ./final_scores/7.0.0a8\n\n" >&2
  exit 1
fi

RUN_NAME_FILE="$1"
BASE_DIR="$2"
STATS_TSV="$3"
FINAL_RESULTS_DIR="$4"

# Check that inputs exist
if [[ ! -f "$RUN_NAME_FILE" ]]; then
  echo "Error: run name file '$RUN_NAME_FILE' not found." >&2
  exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: base directory '$BASE_DIR' not found." >&2
  exit 1
fi

if [[ ! -d "$FINAL_RESULTS_DIR" ]]; then
  echo "Error: final results directory '$FINAL_RESULTS_DIR' not found." >&2
  exit 1
fi

echo -e "PVACTOOLS_VERSION\tRUN_NAME\tHLA\tLENGTH\tALGORITHM\tMEM\tCPUS\tFASTA_SIZE\tSECONDS\tSCORE_COUNT" > $STATS_TSV

STATUS_COMPLETED_FILE_COUNT=0
SCORES_FILE_COUNT=0
TOTAL_RUN_COUNT=$(cat ${RUN_NAME_FILE} | wc -l)

# Loop through each run name
while IFS= read -r RUN_NAME; do
  # Skip blank lines or comments
  [[ -z "$RUN_NAME" || "$RUN_NAME" =~ ^# ]] && continue

  if [[ "$RUN_NAME" =~ ^LEN-([0-9]+)_((HLA-[A-Z]_?[0-9]+_[0-9]+))_ALG-(.+)$ ]]; then
    LEN="${BASH_REMATCH[1]}"
    HLA="${BASH_REMATCH[2]}"
    ALG="${BASH_REMATCH[4]}"
  else
    echo "Warning: could not parse run name '$RUN_NAME'" >&2
    exit 1
  fi

  RUN_DIR=${BASE_DIR}/${LEN}/${ALG}/${RUN_NAME}
  STATUS_COMPLETE_FILE="$RUN_DIR/$RUN_NAME.status.completed"
  SCORES_FILE="$RUN_DIR/$RUN_NAME.scores.tsv.gz"


  #Make sure the run directory was found
  if [[ ! -d "$RUN_DIR" ]]; then
    echo "Warning: Run directory not found for '$RUN_NAME' — aborting" >&2
    exit 1
  fi

  echo -e "\nExploring run: $RUN_NAME\n$RUN_DIR" >&2

  #If the status completion file is found count it
  if [[ -f "$STATUS_COMPLETE_FILE" ]]; then
    ((STATUS_COMPLETED_FILE_COUNT += 1))
  else
    echo -e "\tMissing status completion file for run: $RUN_NAME" >&2
    echo -e "\t$RUN_DIR" >&2
  fi

  #If the scores file is found count it and create a copy
  if [[ -f "$SCORES_FILE" ]]; then
    ((SCORES_FILE_COUNT += 1))
    #copy the scores file to the final location
    cp $SCORES_FILE $FINAL_RESULTS_DIR
  else
    echo -e "\tMissing score file for run: $RUN_NAME" >&2
    echo -e "\t$RUN_DIR" >&2
  fi

  #Calculate the percent completion
  if (( TOTAL_RUN_COUNT > 0 )); then
    PERCENT_RUNS_COMPLETED=$(awk "BEGIN {printf \"%.1f\", ($STATUS_COMPLETED_FILE_COUNT / $TOTAL_RUN_COUNT) * 100}")
    PERCENT_SCORES_FILES_FOUND=$(awk "BEGIN {printf \"%.1f\", ($SCORES_FILE_COUNT / $TOTAL_RUN_COUNT) * 100}")
  else
    PERCENT_RUNS_COMPLETED=0
    PERCENT_SCORES_FILES_FOUND=0
  fi

  #If the job is complete pull stats from the log file
  LOG_FILE="$RUN_DIR/pvacbind.stdout"
  if [[ -f "$STATUS_COMPLETE_FILE" && -f "$LOG_FILE" ]]; then
    awk '/^BENCHMARKING STATISTICS/{f=1; next}
      f && NF==0 {f=0}
      f && /^[A-Z_]+:/ {print $2}
      END { }' "$LOG_FILE" | paste -sd '\t' >> $STATS_TSV
  fi

done < "$RUN_NAME_FILE"

echo "/usr/bin/du -h $BASE_DIR | tail -n1 | cut -f 1" >&2
DISK_USED=$(/usr/bin/du -h $BASE_DIR | tail -n1 | cut -f 1)

#Summarize statistics
echo -e "\nTotal runs: $TOTAL_RUN_COUNT" >&1
echo "Completed runs: $STATUS_COMPLETED_FILE_COUNT" >&1
echo "Percent of runs completed: $PERCENT_RUNS_COMPLETED%" >&1
echo "Scores files found: $SCORES_FILE_COUNT" >&1
echo "Percent of scores files found: $PERCENT_SCORES_FILES_FOUND%" >&1
echo "Total disk space used to store all results: $DISK_USED" >&1
echo -e "\nWrote statistics to: $STATS_TSV\n" >&1

