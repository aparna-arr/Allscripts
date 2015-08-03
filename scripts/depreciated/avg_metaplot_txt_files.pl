#!/usr/bin/env perl

use warnings ;
use strict ;

print "DEPRECIATED: use awk instead\n";

my ($file1, $file2) = @ARGV ;
die "usage: $0 metaplot_outfile1.txt metaplot_outfile2.txt\n" unless @ARGV ;
print "THIS IS INTENDED TO MERGE TWO 2-col FILES and avg EVERY COLUMN\n" ;
print "\nMAKE SURE INFILE COLS ARE CORRESPONDING\n\n" ;

open (FH1, "<", $file1) or die "Could not open $file1\n" ;
open (FH2, "<", $file2) or die "Could not open $file2\n" ;

my @lines ;
my $i = 0;
while (<FH1>) {
  my $line = $_ ;
  chomp $line ;
  my ($bp, $col1, $col2) = split("\t", $line) ;
  $lines[$i]{bp} = $bp ;
  $lines[$i]{col1} = $col1 ;
  $lines[$i]{col2} = $col2 ;
  $i ++ ;
}

close FH1 ;

open (OUT, ">", "outfile.txt") or die "Could not open outfile.txt" ;

my $j = 0 ;
while (<FH2>) {
  my $line = $_ ;
  chomp $line ;

  my ($bp, $col1, $col2) = split("\t", $line) ;
  $bp = ( $bp + $lines[$j]{bp} ) / 2 ;
  $col1 = ( $col1 + $lines[$j]{col1} ) / 2 ;
  $col2 = ( $col2 + $lines[$j]{col2} ) / 2 ;

  my $outline = "$bp\t$col1\t$col2" ;
  print OUT "$outline\n" ;

  $j ++ ;
}

close FH2 ;
close OUT ;

print "outfile is outfile.txt\n"
