#!/usr/bin/env perl
use warnings;
use strict;

my $warning = "
Warnings:
Removes track and comment lines
Outfile is <input>.out

"

my ($wig) = @ARGV;
die "usage: $0 <wig file>\n$warning" unless @ARGV == 1;

print $warning;

open (IN, "<", $wig) or die "Could not open $wig\n";
open (OUT, ">", $wig . ".out") or die "Could not open outfile\n";

while(<IN>) {
  my $line = $_;
  if ($line =~ /track/ || $line =~ /#/) {
    next;
  }
  print OUT $line;
}

close IN;
close OUT;
