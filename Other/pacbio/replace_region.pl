#!/usr/bin/env perl
use warnings ;
use strict ;

my ($fasta) = @ARGV ;
die "usage: $0 <pFC53.fa>\n" unless @ARGV ;

open (IN, "<", $fasta) or die "Could not open $fasta\n" ;

my $header ;
my $seq ;

while (<IN>) {
  my $line = $_ ;
  if ($line =~ /^>/) {
    $header = $line ;
  }
  else {
    $seq = $line ;
  }
}
close IN ;

substr($seq, 963, 83) = "";

open (OUT, ">", $fasta) or die "Could not open $fasta\n" ;

print OUT "$header$seq" ;

close OUT ;
