#!/bin/bash

eval "$(conda shell.bash hook)"
conda activate bioinfo

# download seqs
download_seqs(){

    wget https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/bac120_ssu.fna
}

download_seqs

# taxonomy given as cmd input
taxa=$@
minlen=1500

# loop through taxa and extract seqs from database
for i in $taxa;
do
    mkdir $i"_seqs"
    grep -A1 $i bac120_ssu.fna > $i"_16S.fna"
done


# rename fasta headers removing the stuff we don't need
rename_headers(){

    for i in *.fna;
    do
        outname=${i%.fna}
        cut -d ";" -f7 $i  | cut -d " " -f1,2 | sed s/' '/'_'/g | sed s/'s__'/'>'/g > $outname"_renamed.fna"
    done
}

# use seqtk to filter length of fasta file, keeping only full length
filter_length(){

    for i in *.fna
    do
        outname=${i%.fna}
        seqtk seq -L $minlen $i > $outname"_filt.fna"
    done
}

# align ref seqs using ssu-align
align_seqs(){

    for i in *filt.fna;
    do
        outname=${i%.fna}
        ssu-align --dna $i ${outname}_aligned.fna
done
}

mask_seqs(){

    for i in *aligned.fna;
    do
        outname=${i%.fna}
        ssu-mask $i ${outname}_mask.fna
    done
}

process_seqs(){
    rename_headers
    filter_length
    align_seqs
}

