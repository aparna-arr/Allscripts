#!/usr/bin/env perl
use warnings;
use strict;

my $usage = "
usage: <MAnorm outfile .xls> <new outfile name>

Warnings:
REQUIRES pre-processing, see comments in while loop
";

my ($ma_out, $outfile) = @ARGV;
die $usage unless @ARGV;

open (IN, "<", $ma_out) or die "Could not open $ma_out\n";
open (OUT, ">", $outfile) or die "Could not open $outfile\n";

while (<IN>) {
  my $line = $_;
  chomp $line;

  #9 normal fields of MAnorm
  #cut and paste these new fields:
  # bedtools -c -a DRIPc -b NEAT1 followed by a -a DRIP #10 (check sample order) (requires DRIP/DRIPc to be split out and resorted)
  # "" with MALAT1 #11
  # ACTUALLY doing 11-col with DRIP(c) early prioleau intersect info. $10 = 1 if intersect early prioleau $11 = 1 if nointersect prioleau but intersect early 
  my @fields = split(/\s+/, $line);
  my $newline = $line;

  if ($fields[9] > 0) {
    $newline.="\tz"; # Intersect prioleau early 
  }
  elsif ($fields[10] > 0) {
    $newline .="\tn"; # No intersect prioleau, intersect early
  }
  elsif ($fields[8] > 5) {
    #p-value cut offs

    if ($fields[8] > 5 && $fields[8] <= 10) {
      $newline.="\t1";
    }
    if ($fields[8] > 10 && $fields[8] <= 50) {
      $newline.="\t2";
    }
    if ($fields[8] > 50 && $fields[8] <= 150) {
      $newline.="\t3";
    }
    if ($fields[8] > 150 && $fields[8] <= 300) {
      $newline.="\t4";
    }
    if ($fields[8] > 300) {
      $newline.="\t5";
    }
  }
  else {
    $newline.="\t0";
  }
  print OUT "$newline\n";
} 

close IN;
close OUT;
