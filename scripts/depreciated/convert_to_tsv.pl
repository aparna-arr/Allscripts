#!/usr/bin/env perl
use warnings ;
use strict ;

#this takes a list of single column files
#and puts them into 1 tsv file

print "DEPRECIATED: use awk\n";

my ($input) = @ARGV ;
die "usage: $0 <file list>\n" unless @ARGV ;

chomp $input ;

open (FILES, "<", $input) or die "Couldn't open $input\n" ;
my @files ;
while (<FILES>) 
{
  my $line = $_ ;
  chomp $line ;
  push (@files, $line) ;
}
close FILES ;
my @data ;
my $i = -1 ;
foreach (@files)
{
  my $file = $_ ;
  $i++ ;
  open (my $fh, "<", $file) or die "Couldn't open $file\n";
  while (<$fh>)
  {
    my $line = $_ ;
    chomp $line ; 
    push (@{ $data[$i] }, $line) ; 
  }
  close $fh ;
}

open (OUT, ">", "output.tsv") ;

my $j ;
my $k ;

my $length = scalar @{$data[0]} ;

for ($k = 0 ; $k < $length ; $k++)
{
  for ($j = 0 ; $j < scalar(@data) ; $j++) 
  {
    print OUT "$data[$j][$k]\t" ;  
  }
  print OUT "\n" ;
}
close OUT ;

