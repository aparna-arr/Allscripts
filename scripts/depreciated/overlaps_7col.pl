#!/usr/bin/env perl
use warnings ;
use strict ;

print "DEPRECIATED: Use bedtools intersect -a <> -b <> to get same result instead of bedtools -wo and this intermediate script\n" ;

# takes a bedtools -wo file and outputs a more usual intersect file
# that lists only regions intersected

my ($input) = @ARGV ;
die "usage : $0 <7 col bedtools intersect -wo outfile>\n" unless @ARGV ;
chomp $input ;

open (IN, "<", $input) ;
my @values ;
while (<IN>)
{
  my $line = $_ ;
  chomp $line ;
  my ($chr, $start_a, $end_a, $trash, $start_b, $end_b, $length) = split(/\t/, $line) ; 
  my %hash = (
    chr => $chr ,
    start_a => $start_a ,
    start_b =>$start_b ,
    end_a => $end_a ,
    end_b => $end_b ,
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
  
  print OUT "$values[$i]{chr}\t$large_start\t$overlap_end\n" ;
}
close OUT ;
#print "Rename output file! (intersect_outfile.bed)\n" ;

