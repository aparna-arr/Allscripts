#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
run this script over the bed file intended for metaplot_lowmem*.pl (mine)
expects 6 columns only: chr start end val name strand
strand is neccessary
FIXME this currently should only be used for TSS metaplots
FIXME input bed must have no path, or else outfile is messed up
Outfile is TSS_processed.<input>

";

my ($bed, $window) = @ARGV ;
die "usage : $0 <6 column bed file> <window size>\n$warning" unless @ARGV ;

#print $warning;

my $outbed = "TSS_processed" . $bed ;
open (IN, "<", $bed) or die "Could not open $bed\n" ;

while (<IN>)
{
  my $line = $_ ;
  chomp ($line) ;
  my ($chr, $start, $end, $val, $name, $strand) = split(/\t/, $line) ;
  my $zero ;
  if ($strand eq "+")
  {
    $zero = $start ;
  }
  elsif ($strand eq "-")
  {
    $zero = $end ;
  }
  my $more = $zero + $window ;
  my $less = $zero - $window ;
#  print "[$chr]\t[$less]\t[$more]\t[$val]\t[$name]\t[$strand]\n" ;

  print "$chr\t$less\t$more\t$val\t$name\t$strand\n" ;
}

close IN ;
