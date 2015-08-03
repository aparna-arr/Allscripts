#!/usr/bin/env perl
use warnings ;
use strict ;

my ($up_TSS, $ref_bed) = @ARGV ;
die "usage : <?kbupTSSfile 4col -u> <reference_genelist(refseq)>\n" unless @ARGV ;

print "\nNOTE : script expects ONLY ONE STRAND in TSS file!\nALSO expects 5col refseq file!\n\n" ;

open(IN, "<", $up_TSS) or die "Couldn't open $up_TSS\n" ;

my %hash ;

while (<IN>) {
  my $line = $_ ;
  chomp $line ;
  my ($chr, $start, $end, $strand) = split(/\t/, $line) ;

  my $TSS ;
  if ($strand eq "+") {
    $TSS = $end ;
  }
  elsif ($strand eq "-") {
    $TSS = $start ;
  }

  $hash{$chr}{$TSS} = 0 ; #arbitrary value

}

close IN ;

open(REF, "<", $ref_bed) or die "Could not open $ref_bed\n" ;
open(OUT, ">", "filteredout.bed") ;

while (<REF>) {
  my $line2 = $_ ;
  chomp $line2 ;
  my ($chr2, $start2, $end2, $name, $strand2) = split(/\t/, $line2) ;
  my $TSS2 ;
  if ($strand2 eq "+") {
    $TSS2 = $start2 ;
  }
  elsif($strand2 eq "-") {
    $TSS2 = $end2 ;
  }
  
  if (exists($hash{$chr2}{$TSS2})) {
    print OUT "$line2\n" ;
  }
}

close REF ;
close OUT ;
