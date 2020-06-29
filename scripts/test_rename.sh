rename_headers_gtdb(){

    for i in *.fna;
    do
        # fasta output filename
        outname=${i%.fna}
        # get id from start of line
        # extract species name, remove locus tag and location info, replace spaces with underscores, then strip
        # s__ prefix
        cut -d ";" -f1,7 $i | cut -d "[" -f1 | sed s/'d__Bacteria;'/''/g | sed s/'s__'/''/g | sed s/' '/'_'/ | sed s/' '/'_'/ > ${outname}_intermediate.fna
    done

}

rename_headers_gtdb


