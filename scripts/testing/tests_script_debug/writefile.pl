#!/usr/bin/env perl
use warnings ;
use strict ;

my ($input) = @ARGV ;
die "usage : $0 filename\n" unless @ARGV ;
chomp $input ;

open (IN, ">>", $input) or die "could not open $input\n" ;
print ":wq to savequit"

