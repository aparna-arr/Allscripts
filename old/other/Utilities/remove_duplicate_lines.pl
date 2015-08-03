#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
Returns lines COMPLETELY UNSORTED.
Can be used with any type of file, hence unsorted output
Outputs to input file

";

my ($input) = @ARGV ;
die "usage : <file>\n$warning" unless @ARGV == 1 ;

print $warning;

open (IN, "<", $input) or die "could not open input" ;
my %hash ;
while (<IN>) {
  my $line = $_ ;
  chomp $line ;
  $hash{$line} = 1 ;
}

close IN ;

open (OUT, ">", $input) or die "could not open input" ;

foreach my $lines (keys %hash) {
  print OUT "$lines\n" ;
}

close OUT ;
