#!/usr/bin/env perl
use warnings ;
use strict ;

# This takes the downloaded format of chrom strand start end name 
## to chrom start end strand
## for use with metaplot_lowmem script

print "DEPRECIATED: Use awk '{print \$1 \"\\t\" \$3 \"\\t\" \$4 \"\\t\" \$2}' instead.\n";

my ($input) = @ARGV ;
die "usage : $0 <bedfile>\n" unless @ARGV ;
chomp $input ;
open (IN, "<", $input) or die "Couldn't open $input\n" ;
open (OUT, ">", "NEW$input") or die "Couldn't open output\n" ;

while (<IN>)
{
  my $line = $_ ;
  chomp $line ;
  
  if ($line =~ /^#/) 
  {
    next ;
  }
  
  my ($chr, $strand, $start, $end, $other) = split(/\t/, $line) ;
  print OUT "$chr\t$start\t$end\t$strand\n" ;
}

close IN ;
close OUT ;
