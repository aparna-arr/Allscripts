#!/usr/bin/env perl
use warnings ;
use strict ;

# this takes a find_params summary file and outputs the line with the 
# highest percentage
# 8 column outfile only

my ($input) = @ARGV ;
die "usage : $0 <summary_file.tsv>\n" unless @ARGV ;
chomp ($input) ;
open (IN, "<", $input) or die "Couldn't open $input\n" ;

my $score = 0 ;
my $best_line ;
my $header ;
my $value ;
my ($e_value, $window, $gap) ;

while (<IN>)
{
  my $line = $_ ;
  chomp ($line) ;
  if ($line =~ /E-value/)
  {
    $header = $line ;
    next ;
  }
  if ($input =~ /drip_summary_file/) 
  {
    ($value) = m/^.+\t.+\t.+\t.+\t.+\t.+\t.+\t(.+)$/ ;
  } 
  else
  {
    ($value) = m/^.+\t.+\t.+\t.+\t.+\t.+\t(.+)$/ ;
  }
  if ($value > $score)
  {
    $score = $value ;
    $best_line = $line ;
  }
}
close IN ;
if ($input =~ /drip_summary_file/)
{
  ($e_value, $window, $gap) = $best_line =~ m/^(.+)\t(.+)\t(.+)\t.+\t.+\t.+\t.+\t.+$/ ;
}
else
{
  ($e_value, $window, $gap) = $best_line =~ m/^(.+)\t(.+)\t(.+)\t.+\t.+\t.+\t.+$/ ;
}
my $command = "sh /data/aparna/SICER1.1/SICER/SICER-rb.sh . BED ./temp hg19 1 $window 150 0.64 $gap $e_value\n";
print "$header\n$best_line\n$command" ;
