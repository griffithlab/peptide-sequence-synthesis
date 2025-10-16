#!/usr/bin/env bash
# Usage: ./summarize_pvacbind_jobs.sh <run_name_file> <base_directory>

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Check inputs
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <run_name_file> <base_directory> <stats_tsv_out_file>"
  exit 1
fi

RUN_NAME_FILE="$1"
BASE_DIR="$2"
STATS_TSV="$3"

# Check that inputs exist
if [[ ! -f "$RUN_NAME_FILE" ]]; then
  echo "Error: run name file '$RUN_NAME_FILE' not found."
  exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: base directory '$BASE_DIR' not found."
  exit 1
fi

echo -e "PVACTOOLS_VERSION\tRUN_NAME\tHLA\tLENGTH\tALGORITHM\tMEM\tCPUS\tFASTA_SIZE\tSECONDS\tSCORE_COUNT" > $STATS_TSV

STATUS_COMPLETED_FILE_COUNT=0
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
    echo "Warning: could not parse run name '$RUN_NAME'"
    exit 1
  fi

  RUN_DIR=${BASE_DIR}/${LEN}/${ALG}/${RUN_NAME}
  STATUS_COMPLETE_FILE="$RUN_DIR/$RUN_NAME.status.completed"

  #Make sure the run directory was found
  if [[ ! -d "$RUN_DIR" ]]; then
    echo "Warning: Run directory not found for '$RUN_NAME' — skipping."
    exit 1
  fi

  #If the status completion file is found count it
  if [[ -f "$STATUS_COMPLETE_FILE" ]]; then
    ((STATUS_COMPLETED_FILE_COUNT += 1))
  else
    echo "Missing status completion file for run: $RUN_NAME"
    echo -e "\t$RUN_DIR"
  fi

  #Calculate the percent completion
  if (( TOTAL_RUN_COUNT > 0 )); then
    PERCENT_COMPLETED=$(awk "BEGIN {printf \"%.1f\", ($STATUS_COMPLETED_FILE_COUNT / $TOTAL_RUN_COUNT) * 100}")
  else
    PERCENT_COMPLETED=0
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

#Summarize statistics
echo -e "\nTotal runs: $TOTAL_RUN_COUNT"
echo "Completed runs: $STATUS_COMPLETED_FILE_COUNT"
echo "Percent completed: $PERCENT_COMPLETED%"

echo -e "\nWrote statistics to: $STATS_TSV\n"

