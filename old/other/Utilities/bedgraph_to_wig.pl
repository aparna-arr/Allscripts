#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings
Skips track and comment lines
Outfile: <input>.wig

";

my ($input) = @ARGV ;
die "usage : $0 <bedgraph file>\n$warning" unless @ARGV ;

print $warning;

chomp $input ;
open (BED, "<", $input) or die "Could not open $input\n";
open (WIG, ">", "$input.wig") or die "Couldn't open output\n";
my $prevspan = -1 ;
my $prev_chr = "INIT";
while (<BED>) 
{
  my $line = $_ ;
  chomp $line ;
#  if ($line =~ /^track/ || $line =~ /\#/)
  if ($line !~ /^chr/)
  {
    next ;
  }
  my ($chr, $start, $end, $value) = split (/\s+/, $line) ;
  my $span = $end - $start ;
  if ($span != $prevspan || $chr ne $prev_chr) 
  {
    print WIG "variableStep chrom=$chr span=$span\n" ;
    print WIG "$start\t$value\n" ;
  }
  else
  {
    print WIG "$start\t$value\n" ;
  }
  $prevspan = $span ;
  $prev_chr = $chr ;
}

close BED ;
close WIG ;
