#!/usr/bin/env perl
use warnings;
use strict;

# Takes a wigfile, extracts a small wig of a specific region from it
# Outputs to new wigfile
# Expects sorted wig file

my ($wigfile, $chrom, $start, $end, $outfile) = @ARGV;
die "usage: $0 <sorted wig file> <chr> <start pos> <end pos> <outfile>\n" unless @ARGV;

if ($end < $start) {
  die "end $end is less than start $start!\n";
}

open (IN, "<", $wigfile) or die "Could not open $wigfile\n";
open (OUT, ">", $outfile) or die "Could not open $outfile\n";

#my $stepline = ""; 
my $chr = "INIT";
my $span = 0;

while (<IN>) {
  my $line = $_;
  chomp $line;

  if ($line =~ /^#/ || $line =~ /^track/) {
    next;
  }
  elsif ($line =~ /Step/) {
#    $stepline = $line;
    ($chr, $span) = $line =~ /Step chrom=(.+)\s+span=(\d+)/ ; #FIXME check this regex, check fixedStep format
    if ($chr eq $chrom) {
      print OUT "$line\n";
    }
  } 
  elsif ($line =~ /^\d+/) {
    my ($pos) = $line =~ /(\d+)\t\d+/ ; #FIXME check this regex
    if ($chr eq $chrom && $pos >= $start && $pos + $span <= $end) {
      print OUT "$line\n"; 
    } 
  }
}

close IN;
close OUT;

# FIXME print some kind of error code
