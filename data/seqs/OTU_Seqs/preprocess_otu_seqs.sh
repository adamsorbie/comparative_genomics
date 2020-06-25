#!/bin/bash

# $1 fasta input file
# $2 output file name

set -e
eval "$(conda shell.bash hook)"
conda activate bioinfo

outname=${1%.fasta}
rdp_classifier -q $1 -o ${outname}.txt

otus=$(cut -f1 ${outname}.txt)
genera=$(cut -f21 ${outname}.txt)


paste <(printf '%s\n' "${otus[@]}") <(printf '%s\n' "${genera[@]}") > $2
paste <(echo "${otus[@]}" | tr '' ' \n') <(echo "${genera[@]}" | tr '' ' \n') > $2

# generate otu files for grepping fasta
filename=$(basename ${outname.txt} | cut -f2 -d"-" | cut -f1 -d".")

cut -f1 $2 | sed -e 's/^/>/' > ${filename}_otus.txt

# grep fasta file

# linearise first
single_line=${2%.fasta}_sl.fasta
# call BBMap reformat to convert to single line
# need to check the fastawrap value, possible that 0 will do the trick
reformat.sh in=$2 out=$single_line fastawrap=1000
mkdir -p multi-line-fasta
mv $2 multi-line-fasta
grep -w -A1 -f ${filename}_otus.txt $single_line > ${filename}_seqs.fasta
# empty lines sometimes remain after grep so we will remove them here
sed -i '/^--/d' $single_line

# rename fasta heaers
outfile=$2
awk FNR==NR{  a[">"$1]=$2;next}$1 in a{  sub(/>/,">"a[$1]"|",$1)}1 outfile $single_line > ${single_line%.fasta}_renamed.fasta
awk '# Read the TSV file only
     (NR==FNR) { key=$1; sub(key"[[:space:]]*",""); a[key]=$0; next }
     # From here process the fasta file
     # - if header, perform action:
     /^>/ { match($0,"[|][^|]+"); key=substr($0,RSTART+1,RLENGTH-1);sub(key,a[key]) }
     # print the current line
     1' $1 $2 > $3


