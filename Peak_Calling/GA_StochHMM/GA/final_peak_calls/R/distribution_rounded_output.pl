#!/usr/bin/env perl
use warnings;
use strict;

my ($wig, $round) = @ARGV;
die "usage: $0 <wig file> <num: round to the nearest>\n" unless @ARGV == 2;

open (IN, "<", $wig) or die "Could not open $wig\n";
open (OUT, ">", "outfile.txt") or die "Could not open outfile\n";

my $chrom = "INIT";
my $span = -1;
my %data;
my %values;
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
#    $data{$chrom}{start} = $pos; 
#    $data{$chrom}{end} = $pos + $span;
#    $data{$chrom}{val} = $val;   

    #round val to nearest $round
#    print "rounding\n";
    my $rounded = int(($val / $round) + 0.5)*$round;
    $values{$rounded}+=$span; # don't care about chromosomes, want global
  }
}
close IN;

foreach my $vals (keys %values) {
  # number of bp with that value  value
  print OUT "$values{$vals}\t$vals\n";
}

close OUT;


