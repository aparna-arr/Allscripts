#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;

my $warning = "
Warnings:
run this script over the bed file intended for metaplot_lowmem*.pl (mine)
expects 4 columns only: chr start end strand
Percentile preprocessing script
strand is neccessary
Splits into 10% bins, places in outdir.
FIXME input bed must have no path, or else outfile is messed up
  Use File::Basename
";

my ($dir, $bed) = @ARGV;
die "usage : $0 <outdir> <4 column bed file>\n$warning" unless @ARGV;

print $warning;

my @bin_files;

open (IN, "<", $bed) or die "Could not open $bed\n";

my %peaks; 

while (<IN>)
{
  my $line = $_;
  chomp ($line);
  my ($chr, $pos1, $pos2, $strand) = split(/\t/, $line);
  my ($start, $end, $perc);
  
  if ($strand eq "+")
  {
    $start = $pos1;
    $end = $pos2;
    $perc = ($pos2 - $pos1) * .1;
    push(@{$peaks{plus}}, (start => $start, end => $end, chrom => $chr, strand => $strand, percent => $perc));
  }
  elsif ($strand eq "-")
  {
    $start = $pos2;
    $end = $pos1;
    $perc = ($pos2 - $pos1) * .1;
    push(@{$peaks{minus}}, (start => $start, end => $end, chrom => $chr, strand => $strand, percent => $perc));
  }
}

close IN;

for (my $i = 0; $i < 20; $i++)  { ### not sure if this will work
  push(@bin_files, "$dir/$i.bed");

  open (OUT, ">", "$dir/$i.bed") or die "Could not open outfile for $i\n";

  for (my $j = 0; $j < @{$peaks{plus}}; $j++) {
    print OUT "$peaks{plus}[$j]{chrom}\t" . int($peaks{plus}[$j]{start} - $peaks{plus}[$j]{percent} * (5 - $i)) . "\t" . int($peaks{plus}[$j]{start} - $peaks{plus}[$j]{percent} * (4 - $i)) . "\t$peaks{plus}[$j]{strand}\n";
  } 

  for (my $k = 0; $k < @{$peaks{minus}}; $k++) {
    print OUT "$peaks{minus}[$k]{chrom}\t" . int($peaks{minus}[$k]{start} + $peaks{minus}[$k]{percent} * (4 - $i)) . "\t" . int($peaks{minus}[$k]{start} + $peaks{minus}[$k]{percent} * (5 - $i)) . "\t$peaks{minus}[$k]{strand}\n";
  } 
 
  close OUT;
}
