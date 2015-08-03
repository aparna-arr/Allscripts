#!/usr/bin/env perl
use warnings;
use strict;

my %DESeq = (
  Fibro2_DRIP    => 0.657558055030332,
  Fibro_DRIP     => 0.582041653585039,
  HEK293_DRIP    => 1.21708523435833,
  HeLa_DRIP      => 1.60296349845857,
  K562_DRIP      => 1.0520321704984,
  NT21_DRIP      => 1.63644425680082,
  NT22_DRIP      => 1.18460800934662,
  NT2RNAseA_DRIP => 0.922440881761948,
  NT2RNAseH_DRIP => 0.677098302652388,
  X3T3_DRIP      => 1.25632298099249,
  E14_DRIP       => 0.567891300680534
);

# Treat NT21 DRIP as the "median to normalize agains" therefore divide signals by those values
# E.g. E14_NORM_SIGNAL =  E14_SIGNAL / (0.56789/1.63644)

my ($input, $sample, $output) = @ARGV;

die "usage: <wig file> <sample> <outfile>

sample must be one of:

  Fibro2_DRIP   
  Fibro_DRIP  
  HEK293_DRIP    
  HeLa_DRIP      
  K562_DRIP      
  NT21_DRIP      
  NT22_DRIP     
  NT2RNAseA_DRIP 
  NT2RNAseH_DRIP 
  X3T3_DRIP      
  E14_DRIP
" unless @ARGV == 3;

open (IN, "<", $input) or die "Could not open $input\n";
open (OUT, ">", $output) or die "Could not open $output\n";

my %data;

while(<IN>)
{
  my $line = $_;
  chomp $line;

  if ($line =~ /^variableStep/)
  {
    print OUT "$line\n"; 
  }
  elsif ($line =~ /^\d+/)
  {
    my ($pos, $val) = split(/\t/, $line);
    $val = $val / ($DESeq{$sample} / $DESeq{NT21_DRIP});
    print OUT "$pos\t$val\n";
  }
  else 
  {
    print OUT "$line\n";
  }
}

close IN;
close OUT;

