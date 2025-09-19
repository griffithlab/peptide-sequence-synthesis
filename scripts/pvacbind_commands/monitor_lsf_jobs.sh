#!/bin/bash

PEPTIDE_SET="1K"
ALLELE_SET="first-3"
PVACTOOLS_VERSION="5.5.2"
WORKING_BASE=/storage1/fs1/mgriffit/Active/immune/pvactools_percentiles
RESULTS_BASE=$WORKING_BASE/pvacbind_results
RUN_COMMAND_FILE="${WORKING_BASE}/run_commands_${PEPTIDE_SET}peptides_v${PVACTOOLS_VERSION}_${ALLELE_SET}-alleles.sh"
RUN_NAME_FILE="${WORKING_BASE}/run_names_${PEPTIDE_SET}peptides_v${PVACTOOLS_VERSION}_${ALLELE_SET}-alleles.txt"
SHORT_PAUSE=10
LONG_PAUSE=300

#other parameters
JOB_GROUP="/mgriffit/perc"

#Get the unique command line and the job name for each job
mapfile -t COMMANDS < ${RUN_COMMAND_FILE}
mapfile -t NAMES < ${RUN_NAME_FILE}

#In an infinite loop with a 5 min pause between iterations. Do the following
for i in "${!COMMANDS[@]}"; do
    RUN_NAME="${NAMES[$i]}"
    CMD="${COMMANDS[$i]}"
    if [[ $line =~ LEN-([0-9]+)_.*_ALG-(.+)$ ]]; then
      LEN="${BASH_REMATCH[1]}"
      ALGO="${BASH_REMATCH[2]}"
    fi

    FINAL_OUTDIR=${RESULTS_BASE}/${PVACTOOLS_VERSION}/${LEN}/${ALGO}/${RUN_NAME}
    STATUS_FILE_RUNNING="${FINAL_OUTDIR}/${RUN_NAME}.status.running"
    STATUS_FILE_COMPLETED="${FINAL_OUTDIR}/${RUN_NAME}.status.completed"

    #Check to see if this job has already been run. If so, skip this job
    #Check for stdout that contains "Done: Pipeline finished successfully"?
    #Check for existence of a file written by the submission script?
    RUN_COUNT=$((i + 1))
    echo -e "\nJob count: $RUN_COUNT"
    echo -e "Checking status of job: $RUN_NAME"
    echo -e "Check for existence of status files for running or completed jobs"

    if [[ -f "$STATUS_FILE_RUNNING" ]]; then
        echo "Skipping $RUN_NAME — running status file exists: $STATUS_FILE_RUNNING"
        continue   # go straight to next iteration
    fi

    if [[ -f "$STATUS_FILE_COMPLETED" ]]; then
        echo "Skipping $RUN_NAME — completion status file exists: $STATUS_FILE_COMPLETED"
        continue   # go straight to next iteration
    fi

    echo -e "Status files do not already exist for run: $RUN_NAME - checking whether the job for this run can be submitted to the job group now"


    #If the job has not already been run, check the LSF job group & the number of jobs submitted to that group
    while true; do
        # Re-run bjgroup each loop to get updated counts
        read N_JOBS JOBS_RUNNING JOB_GROUP_LIMIT < <(
            bjgroup -s $JOB_GROUP | awk 'NR==2 {split($9,a,"/"); print $2, a[1], a[2]}'
        )
        # Get number of jobs in the job group actually present in the queue (N_JOBS from above seems to include completed jobs). 
        JOBS_SUBMITTED=$(bjobs -g "$JOB_GROUP" 2>/dev/null | grep -v JOBID | cut -d " " -f 1 | grep -P "^\d+" | wc -l)

	#If the job group is not currently full + 1, submit a new job (i.e. always have one more job in the queue than the size of the job group)
        if (( JOBS_SUBMITTED < JOB_GROUP_LIMIT + 1 )); then
            echo "Job group is not full (submitted=$JOBS_SUBMITTED, running=$JOBS_RUNNING, limit=$JOB_GROUP_LIMIT) ... submitting job"
            echo "$CMD"
            eval "$CMD"
            echo "Waiting $SHORT_PAUSE seconds before submitting another job"
            sleep $SHORT_PAUSE
            break   # exit the while loop after submitting
        else
            echo "Too many jobs already submitted to job group (submitted=$JOBS_SUBMITTED, running=$JOBS_RUNNING, limit=$JOB_GROUP_LIMIT) ... Waiting $LONG_PAUSE seconds to check again"
            sleep $LONG_PAUSE
        fi
    done
done

