#!/usr/bin/env perl

use warnings ;
use strict ;

my ($input) = @ARGV ;
die "usage: $0 <new data Smoothed_hg19....txt>\n" unless @ARGV ;

open (IN, "<", $input) or die "Could not open $input\n" ;
`mkdir newdata_chrs` ;
my %chroms ;
while (<IN>) {
  my $line = $_ ;
  chomp $line ;

  my ($chr, $pos, $val) = split(/\t/, $line) ;
  if ($chr == 23) {
    $chr = "X" ;
  }
  elsif ($chr == 24) {
    $chr = "Y" ;
  }
  $chr = "chr" . $chr ;
  
  $val = ($val + 3) / 6 * 100 ;
  if ($val =~ /nan/i) {
    $val = "NA" ;
  }
  $chroms{$chr} .= "$pos\t$val\n" ;
}
close IN ;
foreach my $chromosome (keys %chroms) {
  open (OUT, ">", "newdata_chrs/$chromosome\_outfile.txt") ;
  print OUT "$chroms{$chromosome}" ;
  close OUT ; 
}
