#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
Expects 1 chromosome wig file
Does not break on variableStep lines : If file has more than 1 chr, will print out all the lines within start, end interval, does print variableStep lines.
outfile: <input>.out

";


my ($wig, $start, $end) = @ARGV;
die "usage: <wig> <start pos> <end pos>\n$warning" unless @ARGV;

print $warning;

open (IN, "<", $wig) or die "Could not open $wig\n";
open (OUT, ">", $wig . ".out") or die "Could not open outfile\n";
while (<IN>) {
  my $line = $_ ;
  chomp $line ;
  
  if ($line =~ /^variableStep/ || $line =~ /^#/ || /^track/) {
    print OUT "$line\n";
  }
  else {
    my ($wigstart, $trash) = split(/\t/, $line) ;
    if ($wigstart >= $start && $wigstart < $end) {
      print OUT "$line\n";
    }
  }
}

close IN;
close OUT;
