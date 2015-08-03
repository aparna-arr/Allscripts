#!/usr/bin/env perl
use warnings;
use strict;

my ($file) = @ARGV;
die "usage: <bed file>\n" unless @ARGV;

open (IN, "<", $file) or die "Could not open $file: $!\n";

while (<IN>) {
  my $line = $_;
  chomp $line;

  my ($chr, $start, $end) = split(/\t/, $line);

  if ($start !~ /^\d+$/ || $end !~ /^\d+$/) {
    print "Error! Line $line\n";
  }

}

close IN;
