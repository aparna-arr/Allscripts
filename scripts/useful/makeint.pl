#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
Expects ONLY 3 col bedfile
Makes start and end -> int
Sorted doesn't matter
Outputs to infile

";

my ($input) = @ARGV ;
die "usage: $0 <3 col bedfile>\n$warning" unless @ARGV ;

print $warning;

open (IN, "<", $input) or die "could not open $input\n" ;
my $file = "" ;
open (OUT, ">", "temp") ; 
while (<IN>) {
  my $line = $_ ;
  chomp $line ;
  if ($line =~ /track/) {
    print OUT "$line\n" ;
    next ;
  }
  my ($chr, $start, $end) = split(/\t/, $line) ;

  $start = int($start) ;
  $end = int($end) ;
  print OUT "$chr\t$start\t$end\n" ;
}

close IN ;
close OUT ;
`mv temp $input`
