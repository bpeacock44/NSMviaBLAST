#!/bin/bash

# Argument Handling
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_file.fastq path/to/scripts"
    exit 1
fi

input_file="$1"
SDIR="$2"

echo "You have indiciated your input file as ${input_file}."

# Check if the input file exists
if [ ! -e "$input_file" ]; then
    echo "Error: $input_file does not exist."
    exit 1
fi

# Check if the script directory exists
if [ ! -e "$SDIR" ]; then
    echo "Error: $SDIR does not exist."
    exit 1
fi

# Define timestamp
timestamp="$(date +"%Y%m%d_%H:%M:%S")"

# Set up the output directory
short="${input_file%.fastq}"
WDIR=$(dirname "$(realpath "$input_file")")
output_dir=${WDIR}/${short}
if [ -d "$output_dir" ]; then
    version=1
    while [ -d "$output_dir"_prev_v"$version" ]; do
        version=$((version + 1))
    done
    new_dir="$output_dir"_prev_v"$version"
    mv "$output_dir" "$new_dir"
    echo "Previous version of output directory found. Renamed existing directory to "${new_dir}". Creating new "${output_dir}"."
fi
cd "$WDIR" || { echo "Failed to move to directory containing the fastq file."; exit 1; }
echo "Output will be stored in directory: ${output_dir}. Creating directory now."
mkdir -p "$output_dir" || { echo "Failed to create the output directory."; exit 1; }
echo " "

# Redirect all output to the log file with a timestamp
output_file="${output_dir}/output_${timestamp}.log"
exec > "$output_file" 2>&1

# Remove duplicate reads
echo "Using usearch fastxuniques to remove duplicate reads. This will be saved as uniq.${input_file}".
# Submit the batch job and capture the job ID
job_id=$(sbatch -p i128 -c 128 "${SDIR}/fastxuniques.sh" ${input_file} ${output_dir} | awk '{print $NF}')
echo "Batch job submitted with ID: $job_id"

# Wait for the submitted job to finish
echo "Waiting for the job to finish..."
while squeue -j "$job_id" -h &>/dev/null; do
    sleep 10
done

# Continue with the rest of the script
echo "Fastxuniques has finished. Continuing with the script..."

echo " "
input_file2="${output_dir}/uniq.${input_file}"

echo "Trimming header. This will be saved as uniq.${input_file}.header_trim."
python ${SDIR}/header_trimmer.py ${input_file2} "${input_file2}.header_trim"
input_file3="${input_file2}.header_trim"

echo "Now running diamond. It will run multiple times until results are sufficient."
# Run Diamond BLAST
bash "${SDIR}/cyclical_blast_and_eval.sh" "${input_file3}" diamond "${output_dir}" 

echo " "
echo "Identifying reads that didn't get a hit. These will be run again through blastn."
# Identify reads with hits in the Diamond results
awk -F'\t' '!/^#/ {seen[$1]++} END {for (val in seen) print val}' "${output_dir}/10.rb0.diamondout" > "${output_dir}/reads_with_hits.txt"

# Subset reads without hits
seqkit grep -vn -f "${output_dir}/reads_with_hits.txt" "$input_file3" -o "${output_dir}/${short}.no_hits.clean.fastq"
seqkit fq2fa "${output_dir}/${short}.no_hits.clean.fastq" -o "${output_dir}/${short}.no_hits.clean.fasta"

echo "Running blastn now."
# Run BLAST again with blastn on missing hit reads
bash "${SDIR}/cyclical_blast_and_eval.sh" "${output_dir}/${short}.no_hits.clean.fasta" blast ${output_dir} 
echo " "
echo "Blasting complete. Merging and reformatting diamondout files."

# Submit the batch job and capture the job ID
job_id=$(sbatch -p i128 -c 128 "${SDIR}/diamondout_merge_and_clean.sh" ${output_dir} | awk '{print $NF}')
echo "Batch job submitted with ID: $job_id"

# Wait for the submitted job to finish
echo "Waiting for the job to finish..."
while squeue -j "$job_id" -h &>/dev/null; do
    sleep 10
done

echo "Batch job with ID $job_id is complete."

# Continue with the rest of the script
echo "Batch job has finished. Continuing with the script..."

echo " "
echo "Merging blast and diamond results and cleaning up for further analysis."

for file in ./${output_dir}/*blastout; do
    if [ -f "$file" ] && [ "$(cat "$file")" = "BLAST query error: CFastaReader: Near line 1, there's a line that doesn't look like plausible data, but it's not marked as defline or comment." ]; then
        mv "$file" "${file}.false"
    fi
done

cat ${output_dir}/*blastout ${output_dir}/all_combined.diamondout.mod3 > ${output_dir}/final_blast_and_diamond.out

grep -v "# BLAST processed" ${output_dir}/final_blast_and_diamond.out > ${output_dir}/final_blast_and_diamond.out2 && echo "# BLAST processed all queries" >> ${output_dir}/final_blast_and_diamond.out2 && mv ${output_dir}/final_blast_and_diamond.out2 ${output_dir}/final_blast_and_diamond.out

python "${SDIR}/header_fixer.py" ${output_dir}

HDIR=/home/bpeacock_ucr_edu/real_projects/PN94_singularity_of_microbiome_pipeline/targeted_microbiome_via_blast/helper_functions
TAXDIR=/sw/dbs/tax_files
tax_files_dir=/sw/dbs/tax_files
    
# This section will create the ASVs2filter.log, which will be used to assign taxonomy. 
# Again, there are two sections - one for if the user didn't specify a filter file and another for if they did.
"${HDIR}/blast_taxa_categorizer.py" \
    -i "${outdir}/final2_blast_and_diamond.out" \
    -k $(awk -F'\t' '$4=="Keep"{print "'${TAXDIR}'/"$1"__"$3"_txid"$2"_NOT_Environmental_Samples.txt"}' <(echo -e "Name\tID\tRank\tAction\nEukaryota\t2759\tk\tKeep\nBacteria\t2\tk\tKeep\nArchaea\t2157\tk\tKeep\nPlaceholder\t0\tk\tReject") | paste -sd, -) \
    -e $(awk -F'\t' '$4=="Keep"{print "'${TAXDIR}'/"$1"__"$3"_txid"$2"_AND_Environmental_Samples.txt"}' <(echo -e "Name\tID\tRank\tAction\nEukaryota\t2759\tk\tKeep\nBacteria\t2\tk\tKeep\nArchaea\t2157\tk\tKeep\nPlaceholder\t0\tk\tReject") | paste -sd, -) \
    -r $(awk -F'\t' '$4=="Reject"{print "'${TAXDIR}'/"$1"__"$3"_txid"$2"_NOT_Environmental_Samples.txt"}' <(echo -e "Name\tID\tRank\tAction\nEukaryota\t2759\tk\tKeep\nBacteria\t2\tk\tKeep\nArchaea\t2157\tk\tKeep\nPlaceholder\t0\tk\tReject") | paste -sd, -) \
    -t "$tax_files_dir" \
    -m "${TAXDIR}/merged.dmp"

python "${SDIR}/asv2filter_mod.py"

# I got an error once where the line in the blast file didn't parse properly, so the ASVs2filter.log had one entry it couldn't parse. Went in and fixed manually.

#assign taxonomy using the otus2filter.log
# DON'T BE IN QIIME FOR THIS
export MODULEPATH=$MODULEPATH:/sw/spack/share/spack/modules/linux-centos7-cascadelake/

module load py-docopt
module load py-biopython
module load py-xmltodict

"${SDIR}/diamond_blast_assign_taxonomy.py" -i new_ASVs2filter.log --db taxonomyDB.json -m beth.b.peacock@gmail.com --assign_all --add_sizes -o ${output_dir}/read_assignments.txt

# then remove the .xml files # 
rm *.xml

# Store the lines matching the pattern in a variable
matched_lines=$(grep 'size=[^1][0-9]*' ${input_file})

# Store the parts between "@" and the first space in an array
IFS=$'\n' read -rd '' -a var <<<"$(echo "$matched_lines" | cut -d "@" -f 2 | cut -d " " -f 1)"

# Output the array elements
for element in "${var[@]}"; do
    echo "$element"
done

# Iterate through each line matching the pattern
while IFS= read -r line; do
    # Extract the ID from the line
    id=$(echo "$line" | cut -d "@" -f 2 | cut -d " " -f 1)

    # Find the matching line in read_assignment_final.txt
    matched_line=$(grep "$id" ${output_dir}/read_assignments.txt)

    # Extract the size value from the original line
    size=$(echo "$line" | grep -o 'size=[0-9]*' | cut -d "=" -f 2)

    # Duplicate the matched line as many times as specified by size
    for ((i = 2; i <= size; i++)); do
        echo "$matched_line" >> ${output_dir}/read_assignments.txt
    done

done < <(grep 'size=[^1][0-9]*' ${input_file})


${SDIR}/summary_gen.py ${output_dir}/read_assignments.txt ${output_dir}/read_assignment_summary.txt
