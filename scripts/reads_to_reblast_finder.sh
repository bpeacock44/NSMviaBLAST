#!/bin/bash
# find reads that did not get sufficient results to determin LCA - wrapper script for reads_to_reblast_finder.py
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
python  "${SDIR}/reads_to_reblast_finder.py" "${1}" "${4}" "${3}/${2}.txt"
seqkit grep -n -f "${3}/${2}.txt" "${3}/uniq.${3}.fastq.header_trim" -o "${3}/${2}.fastq" 
