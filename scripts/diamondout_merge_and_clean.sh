#!/bin/bash
# Set script directory.
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

outdir="$1"

# Concatenate DIAMOND outputs
output_file="all_combined.diamondout"  # The final output file where all content will be concatenated

# Remove output file if it already exists
rm -f ${outdir}/$output_file
# Iterate over each .diamondout.final file
for final_file in ${outdir}/*diamondout; do
    cat "$final_file" >> ${outdir}/$output_file
done

echo "Diamond concatenation complete."

# remove all problematic lines.
grep -vE '^(#|real|user|sys|$)' ${outdir}/all_combined.diamondout > ${outdir}/all_combined.diamondout.mod
# remove accidental duplicate lines
sort ${outdir}/all_combined.diamondout.mod | uniq > ${outdir}/all_combined.diamondout.mod2

mv ${outdir}/all_combined.diamondout.mod2 ${outdir}/all_combined.diamondout.mod

python  "${SDIR}/missing_taxid_finder.py" ${outdir}

sed 's/.*\[\([^]]*\)\].*/\1/' ${outdir}/missing_taxids.txt > ${outdir}/missing_taxid_names.txt
/home/bpeacock_ucr_edu/real_projects/storage/taxonkit name2taxid ${outdir}/missing_taxid_names.txt | awk -F'\t' '{print $2}' > ${outdir}/found_taxids.txt
paste -d'\t' <(cut -f1-7 ${outdir}/missing_taxids.txt | awk '{gsub(/^\t+|\t+$/,""); print}') ${outdir}/found_taxids.txt <(cut -f8- -s ${outdir}/missing_taxids.txt | awk '{gsub(/^\t+|\t+$/,""); print}') > ${outdir}/fixed_missing_taxids.txt
cat ${outdir}/fixed_missing_taxids.txt ${outdir}/all_combined.diamondout.mod2 > ${outdir}/all_combined.diamondout.mod3

# sort by ID column 
sort -k1,1n ${outdir}/all_combined.diamondout.mod3 > ${outdir}/all_combined.diamondout.mod2

# This AWK script groups lines based on the first field and prints a header for each group.
awk '
BEGIN {
    FS="\t";  # Set field separator to tab
    OFS="\t"; # Set output field separator to tab
}
{
    if($1 != prev && NR != 1) { 
        print_header(prev, count);
        for(line in group) print group[line];
        delete group;  # Reset group array
        count=0;  # Reset count 
    }
    prev = $1;  # Set the previous ID to the current one
    count++;  # Increase the count of records with the same ID
    group[count] = $0;  # Store the line in the group array
}
END {
    print_header(prev, count);
    for(line in group) print group[line];
}
function print_header(id, num) {
    print "# BLASTN 2.12.0+";
    print "# Query: " id " 1:N:0:TGACCA;size=1";
    print "# Database: /sw/dbs/nr_database_and_diamond/nr_diamond.dmnd";
    print "# Fields: query id, subject id, % identity, alignment length, mismatches, evalue, bit score, subject tax ids, subject title, % query coverage per subject";
    print "# " num " hits found";
}
' ${outdir}/all_combined.diamondout.mod2 > ${outdir}/all_combined.diamondout.mod3
