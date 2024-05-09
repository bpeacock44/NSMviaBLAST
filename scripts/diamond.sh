#!/bin/bash 
# slurm diamond submission script
DB=/sw/dbs/nr_database_and_diamond/nr_diamond.dmnd
OPTS="qseqid sseqid pident length mismatch evalue bitscore staxids stitle"
TASK=blastx
MAXTSEQS=$2
EVAL=1e-3
INFASTA=$1
# time MUST be at the front, or the parser won't know when diamond output ends.
time /sw/dbs/nr_database_and_diamond/diamond ${TASK} -q ${INFASTA} -d ${DB} -p 128 --evalue $EVAL -k $MAXTSEQS --header -f 6 qseqid sseqid pident length mismatch evalue bitscore staxids stitle
