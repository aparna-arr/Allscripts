#!/usr/bin/env perl
use warnings ;
use strict ;

my ($fasta) = @ARGV ;
die "usage:$0 <pFC53.fa>\n" unless @ARGV ;

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
$seq =~ tr/actg/tgac/ ;
$seq = scalar reverse $seq ;

open (OUT, ">", $fasta . "_conv") or die "Could not open converted_$fasta\n" ;

print OUT "$header$seq" ;

close OUT ;

