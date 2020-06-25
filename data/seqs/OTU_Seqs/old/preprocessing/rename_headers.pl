#!/usr/bin/perl
use strict;
use warnings;

# Read the annotations file
print"Enter header file...\n";
my $header = <STDIN>;
open(my $fh_annotations, $header) or die "Can't open $header";
my @annotfile = <$fh_annotations>;
close $fh_annotations;
# file where output will be saved 
my $result = 'result.fasta';
open(RESULT, '>', $result);
# Read the sequence file
print"Enter sequence file...\n";
my $seq = <STDIN>;
open(my $fh_genes, $seq) or die "Can't open $seq";
my @seqfile = <$fh_genes>;
close $fh_genes;
# Process the header data
my %names; 
foreach my $line (@annotfile) {
  chomp $line;                      
  my @fields = split /\t/, $line;   
  $names{$fields[0]} = $fields[1];  
}
# Process the sequence data
foreach my $line (@seqfile) {
  if ($line =~ m/>(.+)$/) {
     if (exists $names{$1}) {
       $line =~ s/($1)/$names{$1}/;
      }
  }
print RESULT $line;

}
