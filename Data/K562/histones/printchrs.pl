#!/usr/bin/env perl
use warnings;
use strict;

my ($file) = @ARGV;
die "usage: $0 <wigfile>\n" unless @ARGV;

open (FH, "<", $file);

while(<FH>) {
  my $line = $_;

  if ($line =~ /variableStep/) {
    print $line;
  }
}

close FH;
