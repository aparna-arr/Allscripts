#!/usr/bin/env perl
use warnings ;
use strict ;

my ($bed_output, $genelist) = @ARGV ;
die "usage: $0 <output bedtools intersect -c file> <genelist that corresponds with -a>\n" unless @ARGV ;

print "\nNOTE : $bed_output and $genelist must be the same #lines and in same order!\n" ;

open (BED, "<", $bed_output) or die "Couldn't open $bed_output\n" ;
my $count = 0 ;

my %noantisense ;
my %antisense ;

while (<BED>) {
  my $line = $_ ;
  chomp $line ;
  my ($intersects) = $line =~ /^chr.+\t\d+\t\d+\t[-|+]\t(\d+)/ ;
#  print "$intersects\n" ;
  if ($intersects == 0) {
    $noantisense{$count} = 0 ; 
  }
  else {
    $antisense{$count} = $intersects ;
  }
  $count++ ;
}

close BED ;

open(GENE, "<", $genelist) or die "Couldn't open $genelist\n" ;
open(ANTI, ">", "antisense_present.bed") ;
open(NOANTI, ">", "no_antisense_present.bed") ;

my $count2 = 0;
while (<GENE>) {
  my $line2 = $_ ;
  chomp $line2 ;

  if (exists($noantisense{$count2})) {
    print NOANTI "$line2\n" ;
  }
  elsif(exists($antisense{$count2})) {
    print ANTI "$line2\n" ;
  }
  $count2++ ;
}
if ($count2 != $count) {
  print "ERROR! bed -c out lines ($count) != genelist lines ($count2)! Do not trust outfiles!\n" ;
}

close BED ;
close ANTI ;
close NOANTI ;

