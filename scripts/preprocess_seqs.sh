#!/bin/bash

#### Description: downloads, preprocesses and aligns a given set of reference seqs for building a reference phylogenetic tree
####
####
#### Author: Adam Sorbie 2020-06

# ENV

set -e

# activate correct conda env
eval "$(conda shell.bash hook)"
conda activate bioinfo

# data directory where output files will be moved to
data_dir="/home/adamsorbie/comparative_genomics/data/seqs"
work_dir="/home/adamsorbie/comparative_genomics"

### FUNCTIONS

# download seqs from gtdb and curated mibc seqs from your dropbox
download_seqs(){

    wget https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/bac120_ssu.fna

    wget -O mibc_16S_seqs.zip https://www.dropbox.com/s/5lgiuntbi9ndztz/mibc_16S_seqs.zip?dl=1

}


# rename fasta headers removing the stuff we don't need
rename_headers_gtdb(){

    for i in *_gtdb.fna;
    do
        # fasta output filename
        outname=${i%.fna}
        # extract species name, remove locus tag and location info, replace spaces with underscores, then strip
        # s__ prefix
        cut -d ";" -f1,7 $i  | cut -d "[" -f1 | sed s/'d__Bacteria;'/''/g | sed s/'s__'/''/g | sed s/' '/'_'/ | sed s/' '/'_'/ > ${outname}"_renamed.fna"
        rm -f $i
    done
}

rename_headers_mibc(){

    unzip mibc_16S_seqs.zip
    for i in *_mibc.fasta;
    do
        # create outname by dropping extension
        outname=${i%.fasta}
        # extract id and genus and species name, then remove spaces
        cut -d" " -f1-3 $i | sed s/" "/"_"/g > ${outname}_renamed.fna
        rm -f $i
    done

}

# joing gtdb and mibc seqs
cat_dbs(){

    for i in *_gtdb_renamed.fna;
    do
        taxon=$(echo $i | cut -d"_" -f1)
        pair_file=$(ls ${taxon}*_mibc*)
        cat $i $pair_file > ${taxon}_ref_seqs.fna
    done
}

# some files contained extra "-" characters which cause a problem with ssu-align, this function removes them
rm_extra_chars(){
    for i in *_filt.fna;
    do
        sed -i 's/-//g' $i
    done
}


# use seqtk to filter length of fasta file, keeping only full length
filter_length(){

    for i in *_ref_seqs.fna
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

### START OF SCRIPT

echo "Script started `date`"

cd $work_dir || exit

# call function to download sequences
download_seqs

# taxonomy given as cmd input
taxa=$@

# loop through taxa and extract seqs from database
for i in $taxa;
do
    grep -A1 $i bac120_ssu.fna > ${i}"_gtdb.fna"
done

# run pipeline
process_seqs() {

    # set minimum sequence length for inclusion in tree
    minlen=1400

    # make directory for downloaded 16S seqs and move file
    mkdir -p db_seqs
    mv bac120_ssu.fna db_seqs

    # rename headers in fasta files so only genus and species name remain
    rename_headers_gtdb
    rename_headers_mibc

    # cat mibc and gtdb database seqs
    cat_dbs

    # exclude seqs less than $minlen
    filter_length

    # remove extra characters in seqs
    rm_extra_chars

    # perform alignment and masking of seqs using ssu-align
    align_seqs
    mask_seqs
    # mv output directories to data
    mv *_aligned db_seqs/ $data_dir
    echo "PREPROCESSING COMPLETE"
}

process_seqs

# clean up directory
mkdir -p ${data_dir}/{filtered, renamed}
mv *_filtered ${data_dir}/filtered
mv *_renamed ${data_dir}/renamed

# find files with afa extension (ssu-mask output) and rename as fna
find $data_dir -depth -name *.afa -exec sh -c 'mv  .fna' _ {} \;

echo "script completed: `date`"

