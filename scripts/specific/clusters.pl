#!/usr/bin/env perl
use warnings ;
use strict ;

#example input file : clusters_input.tsv
#example output file : modified_output.bed
#used with APOBEC data 
#Data listed many peaks in a cluster. Each cluster was numbered, so data was
##  peak  cluster1
##  peak  cluster1
##  peak  cluster2
#etc. This takes a file and outputs beg pos and end pos of each cluster
#essentially adding up the peaks

#delete header line first
my ($input) = @ARGV ;
die "usage = <output .tsv file>\n" unless @ARGV ;

open (IN, "<", $input) or die "Couldn't open $input\n" ;

my $prev_cluster = -1 ;
my %peaks ;
while (<IN>)
{
  my $line = $_ ;
  chomp $line ;
  my ($chr, $start, $end, $strand, $cluster) = split(/\t/, $line) ;
  
  if (exists $peaks{$cluster}) 
  {
    $peaks{$cluster}{end} = $end ; #assumes tsv file is in increasing order
  }
  else 
  {
     $peaks{$cluster}{start} = $start ;
     $peaks{$cluster}{end} = $end ;
     $peaks{$cluster}{chrom} = $chr ;
    
#    $peaks{$cluster} = (
#      start => $start ,
#      end => $end ,
#      chrom => $chr 
#    ) ;
  }
}

close IN ;

open (OUT, ">", "modified_output.bed") or die "Couldn't open output\n";

foreach my $peak (keys %peaks)
{
  print OUT "$peaks{$peak}{chrom}\t$peaks{$peak}{start}\t$peaks{$peak}{end}\n" ;
}

close OUT ;
