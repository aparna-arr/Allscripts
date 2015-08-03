#!/usr/bin/env perl
use warnings ;
use strict ;
use Data::Dumper ;

# takes a bedtools -wo file and outputs a more usual intersect file
# that lists only regions intersected

my ($input) = @ARGV ;
die "usage : $0 <bedtools intersect -wo outfile>\n" unless @ARGV ;
chomp $input ;

open (IN, "<", $input) ;
my @values ;
while (<IN>)
{
  my $line = $_ ;
  chomp $line ;
#  my ($chr, $start_a, $end_a, $score_a, $start_b, $end_b, $score_b, $length) = $line =~ /(.+)\t(.+)\t(.+)\t(.+)\t.+\t(.+)\t(.+)\t(.+)\t(.+)/ ;
  my ($chr, $start_a, $end_a, $score_a, $trash, $start_b, $end_b, $score_b, $length) = split(/\t/, $line) ; 
  my %hash = (
    chr => $chr ,
    start_a => $start_a ,
    start_b =>$start_b ,
    end_a => $end_a ,
    end_b => $end_b ,
    score_a => $score_a ,
    score_b => $score_b ,
    length => $length 
  ) ;
  push (@values, \%hash) ;
}
close IN ;
open (OUT, ">", "intersect_outfile.bed") ;

my $i ;
for ($i = 0 ; $i < scalar(@values) ; $i++)
{
  my $large_start = $values[$i]{start_a} ;
  if ($values[$i]{start_b} > $values[$i]{start_a})
  {
    $large_start = $values[$i]{start_b} ;
  }
  my $overlap_end = $large_start + $values[$i]{length} - 1 ;
  my $score = ($values[$i]{score_a} + $values[$i]{score_b}) / 2 ;
  
  print OUT "$values[$i]{chr}\t$large_start\t$overlap_end\t$score\t$values[$i]{length}\n" ;
}
close OUT ;
print "Rename output file! (intersect_outfile.bed)\n" ;

