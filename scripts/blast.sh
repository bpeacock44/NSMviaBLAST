#!/bin/bash 
# slurm blast submission script
export MODULEPATH=$MODULEPATH:/sw/spack/share/spack/modules/linux-centos7-cascadelake/
module load blast-plus
D=/sw/dbs/blast_db_download/nt; #<-this IS a V5 blast db (NCBI is now using 'nt' again not 'nt_v5')
OPTS="qseqid sseqid pident length mismatch evalue bitscore staxids stitle"
TASK=blastn
MAXTSEQS=$2  
INFASTA=$1
EVAL=0.001
CPUs=128
blastn -task $TASK -db $D -query $INFASTA -max_target_seqs $MAXTSEQS -evalue $EVAL -num_threads $CPUs -outfmt "7 $OPTS" 
