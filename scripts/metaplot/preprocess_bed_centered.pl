#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
run this script over the bed file intended for metaplot_lowmem*.pl (mine)
expects 5 columns only: chr start end val strand
strand is neccessary
FIXME this currently should only be used for CENTERED metaplots
out is STDOUT
";

my ($bed, $window) = @ARGV ;
die "usage : $0 <5 column bed file> <window size>\n$warning" unless @ARGV ;

print $warning;

open (IN, "<", $bed) or die "Could not open $bed\n" ;

while (<IN>)
{
  my $line = $_ ;
  chomp ($line) ;
  my ($chr, $start, $end, $tab, $val, $name, $strand) = split(/\t/, $line) ;
  my $zero  = int(($end - $start) / 2) + $start;
  my $more = $zero + $window ;
  my $less = $zero - $window ;

  print "$chr\t$less\t$more\t$val\t$name\t$strand\n" ;
}

close IN ;
