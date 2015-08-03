#!/usr/bin/env perl
use warnings;
use strict;

my ($wig) = @ARGV;
die "usage: $0 <wig file>\n" unless @ARGV == 1;

open (IN, "<", $wig) or die "Could not open $wig\n";
open (OUT, ">", "wig2bed_outfile.txt") or die "Could not open outfile\n";

my $chrom = "INIT";
my $span = -1;
my %data;
#my %values;
while(<IN>) {
  my $line = $_;
  chomp $line;

  if ($line =~ /\#/ | $line =~ /track/) {
    next;
  }

  if ($line =~ /^variableStep/) {
    ($chrom, $span) = $line =~ /^variableStep chrom=chr(.+) span=(.+)$/;
  }
  else {
    my ($pos, $val) = split (/\t/, $line);
    push(@{$data{$chrom}}, {start => $pos, end => $pos + $span, val => $val});   

    #round val to nearest $round
#    print "rounding\n";
#    my $rounded = int(($val / $round) + 0.5)*$round;
#    $values{$rounded}+=$span; # don't care about chromosomes, want global
  }
}
close IN;

#foreach my $vals (keys %values) {
  # number of bp with that value  value
#  print OUT "$values{$vals}\t$vals\n";
#}

foreach my $chr (sort keys %data) {
  for (my $i = 0; $i < @{$data{$chr}}; $i++) {
    print OUT "$chr\t$data{$chr}[$i]{start}\t$data{$chr}[$i]{end}\t$data{$chr}[$i]{val}\n";
  }
}

close OUT;


