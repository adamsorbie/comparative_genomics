#!/usr/bin/env python

from Bio import AlignIO
import argparse

def main():
    """

    parse alignment in fasta format and output as relaxed phylip (w/o ten character limit)
    :return: alignment in phylip format

    """

    parser = argparse.ArgumentParser(description="DESCRIPTION\n"
                                     "This script parses an alignment in fasta format and outputs the \n"
                                     "alignment in relaxed phylip format, which does not limit the \n"
                                     "number of characters in fasta headers. \n"
                                     "\n\n=====================BASIC USAGE============================\n"
                                     "\n$ fasta2_phylip.py -f in.fna -o out.phylip", formatter_class=argparse.RawTextHelpFormatter)


    parser.add_argument("-f", "--fasta", required=True, type=str, help="Name of input alignment in fasta format")
    parser.add_argument("-o", "--output", required=True, type=str, help="Name out output phylip file")
    args = parser.parse_args()

    # read fasta alignment
    in_handle = open(args.fasta, "rU")
    out_handle = open(args.output, "w")

    alignment = AlignIO.parse(in_handle, "fasta")
    AlignIO.write(alignment, out_handle, "phylip-relaxed")

    out_handle.close()
    in_handle.close()

if __name__ == "__main__":
    main()


