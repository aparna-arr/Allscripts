#!/usr/bin/env perl
use warnings ;
use strict ;

#USELESS can do this much much faster with awk
# takes a bed file and outputs first 3 columns to a new file

print "DEPRECIATED: use awk\n";

my ($input) = @ARGV ;
die "usage: $0 <bed file>\n" unless @ARGV ;

chomp $input ;

open (IN, "<", $input)  or die "Couldn't open $input\n" ;
open (OUT, ">", "MOD_$input") or die "Couldn't open output\n" ;
while (<IN>) 
{
  my $line = $_ ;
  chomp $line ;
  my ($chr, $start, $end, $trash) = split(/\t/, $line) ;
  print OUT "$chr\t$start\t$end\n" ;
}

close IN ;
close OUT ;
