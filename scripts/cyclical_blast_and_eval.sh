#!/bin/bash

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <name-of-fastq-file> <blast_type> <out_dir>"
    exit 1
fi

fastq_file="$1"
blast_type="$2"
short="$3"

if [ ! -f "$fastq_file" ]; then
    echo "Error: File $fastq_file not found."
    exit 1
fi

# Set strict mode
set -euo pipefail

# Define initial values
reblast_iteration="rb0"
maxseqs=10

first_run=true  # Add a flag for the first run

criteria_met() {
    if $first_run; then
        echo "Skipping criteria check for the first run."
        return 0
    fi

    echo "Checking criteria..."
    reblast_file="${short}/${blast_type}.${reblast_iteration}.txt"
    
    # Check if the reblast file has any lines
    if [ ! -s "$reblast_file" ] || [ $(wc -l < "$reblast_file") -eq 0 ]; then
        echo "${reblast_file} is empty. Ending the loop."
        return 1 # End if the reblast file is empty
    else
        echo "${reblast_file} has content. Continuing..."
    fi

    return 0 # Continue if reblast file has content
}

while criteria_met; do
    job_ids=()

    echo "Starting first batch of jobs..."
  
    # Decide on the file to use based on the run
    if $first_run; then
        input_file="$1"
    else
        input_file="${short}/${2}.${reblast_iteration}.fastq"
    fi
  
    # Capture the job ID
    job_id=$(sbatch -p i128 -c 128 -o ${short}/${maxseqs}.${reblast_iteration}.${2}out  "${SDIR}/${2}.sh" $input_file ${maxseqs} | awk '{print $NF}')
    echo "Job submitted with ID: $job_id for $input_file"
    job_ids+=($job_id)

    # Create the dependency string
    deps_string="afterany:"$(IFS=":"; echo "${job_ids[*]}")
    echo "Job dependency string: $deps_string"

    echo "Starting second batch of jobs with dependency: $deps_string"
    second_batch_job_ids=()

    next_reblast_value() {
        local current=$1
        case $current in
            "rb0") echo "rb1" ;;
            "rb1") echo "rb2" ;;
            "rb2") echo "rb3" ;;
            "rb3") echo "completed" ;;
            *) echo "error"; exit 1 ;;
        esac
    }

    next_value=$(next_reblast_value $reblast_iteration)
    if [[ "$next_value" == "completed" ]]; then
        echo "All reblast iterations have been completed."
        exit 0
    elif [[ "$next_value" == "error" ]]; then
        echo "Unknown reblast iteration value: $reblast_iteration"
        exit 1
    fi

    job_id=$(sbatch --dependency=${deps_string} -p i128 -c 128  "${SDIR}/reads_to_reblast_finder.sh" ${short}/${maxseqs}.${reblast_iteration}.${2}out ${2}.$next_value ${short} ${maxseqs} | awk '{print $NF}')
    second_batch_job_ids+=($job_id)

    # Wait for the second batch jobs to complete
    echo "Waiting for second batch jobs to complete..."
    while true; do
        active_jobs=$(squeue -j "${second_batch_job_ids[@]}" | tail -n +2 | wc -l)
        
        if (( active_jobs == 0 )); then
            break
        fi
        sleep 60
    done

    echo "All second batch jobs have completed. Adjusting maxseqs and reblast iteration values..."
    case $reblast_iteration in
        "rb0") maxseqs=5000; reblast_iteration="rb1" ;;
        "rb1") maxseqs=20000; reblast_iteration="rb2" ;;
        "rb2") maxseqs=10000000; reblast_iteration="rb3" ;;
        "rb3") echo "Completed all reblast iterations."; exit 0 ;;
    esac

    first_run=false
done
