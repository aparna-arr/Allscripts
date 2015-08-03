#!/usr/bin/env perl
use warnings ;
use strict ;

# used to filter a scoreisland file . Change the 
#  if ($score >=500)
#  line to whatever the score cutoff is


my ($input) = @ARGV ;
die "usage : $0 <.scoreisland>\n" unless @ARGV ;
chomp ($input) ;
open (IN, "<", $input) or die "couldn't open $input";
open (OUT, ">", "filtered.scoreisland") ;
while (<IN>)
{
  my $line = $_ ;
  chomp $line ;
  if ($line =~ /^track/)
  {
    next ;
  }
  my ($score) = m/.+\t.+\t.+\t(.+)/ ;
  if ($score >=500)
  {
    print OUT "$line\n"
  }
}
close IN ;
close OUT ;
