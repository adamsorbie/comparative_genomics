#!/bin/bash

# To-do


# 1. comment script properly
# 2. add code to give download seqs other options
# 3. check taxa only alphabetical characters
# 4. potentially add trimming to aligned seqs
set -e
# activate correct conda env
eval "$(conda shell.bash hook)"
conda activate bioinfo

# data directory where output files will be moved to
data_dir="/home/adamsorbie/microbial_comp_gen/comparative_genomics/data/seqs"

# download seqs
download_seqs(){

    wget https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/bac120_ssu.fna

    wget https://www.dropbox.com/s/5lgiuntbi9ndztz/mibc_16S_seqs.zip?dl=1

    unzip mibc_16S_seqs.zip
}

download_seqs

# taxonomy given as cmd input
taxa=$@

# loop through taxa and extract seqs from database
for i in $taxa;
do
    grep -A1 $i bac120_ssu.fna > $i"_16S.fna"
done

# rename fasta headers removing the stuff we don't need
rename_headers(){

    for i in *.fna;
    do
        outname=${i%.fna}
        cut -d ";" -f7 $i  | cut -d " " -f1,2 | sed s/' '/'_'/g | sed s/'s__'/'>'/g > $outname"_renamed.fna"
        rm -f $i
    done
}

rm_extra_chars(){
    for i in *.fna;
    do
        sed -i 's/-//g' $i
    done
}

# use seqtk to filter length of fasta file, keeping only full length
filter_length(){

    for i in *.fna
    do
        outname=${i%.fna}
        seqtk seq -L $minlen $i > $outname"_filt.fna"
        rm -f $i
    done
}

# align ref seqs using ssu-align
align_seqs(){

    for i in *filt.fna;
    do
        outname=${i%.fna}
        ssu-align --dna $i ${outname}_aligned
done
}
# perform weak masking of seqs (remove bad alignments, trim columns) pf and pt settings from picrust2 preprint
mask_seqs(){

    for i in *_aligned;
    do
        ssu-mask --afa --dna --pf 0.001 --pt 0 $i
    done
}

# run pipeline
process_seqs() {

    minlen=1500

    # make directory for downloaded 16S seqs and move file
    mkdir db_seqs
    mv bac120_ssu.fna db_seqs

    # rename headers in fasta files so only genus and species name remain
    rename_headers
    # exclude seqs less than $minlen
    filter_length

    # remove extra characters in seqs
    rm_extra_chars

    echo "Enter seqs to concatenate if any: "
    read seqs_cat
    if [[ -v seqs_cat ]]
    then
        cat $seqs_cat > concat_seqs_filt.fna
        rm $seqs_cat
    fi
    # perform alignment and masking of seqs using ssu-align
    align_seqs
    mask_seqs
    # mv output directories to data
    mv *_aligned db_seqs/ $data_dir
    echo "PREPROCESSING COMPLETE"
}

process_seqs

find $data_dir -depth -name *.afa -exec sh -c 'mv  .fna' _ {} \;

