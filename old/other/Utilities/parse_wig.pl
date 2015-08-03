#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
Assumes wig has 1 variable step line per chromosome
Searches all lines, not just variableStep lines, for pattern
If pattern is found, copies line and all following line until next variableStep line
Outfile: <pattern>.wig

";

my ($wig, $pattern) = @ARGV ;
die "usage : $0 <wig file> <pattern>\n$warning" unless @ARGV;

print $warning;

open (IN, "<", $wig) or die "Could not open $wig\n" ;
open (OUT, ">", "$pattern.wig") or die "Could not open $pattern.wig" ;
my $continue = 0 ;
while (<IN>) {
  my $line = $_ ;
  chomp $line ;
  if ($line =~ /^variableStep/ && $continue == 1)
  {
    last ;
  }

  if ($line =~ /$pattern/)
  {
    $continue = 1 ;
  }
  
  if ($continue == 1)
  {
    print OUT "$line\n" ;
  }
}

close IN ;
close OUT ;

