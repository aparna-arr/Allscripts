#!/usr/bin/env perl
use warnings ;
use strict ;


my $sum = 0 ;
print "Enter : " ;

while(1) {
  my $num = <> ;
  chomp $num ;
  if ($num =~ /die/) {
    die "Dying!\n" ;
  }
  elsif ($num =~ /clear/) {
    print "Clearing sum!\n" ;
    $sum = 0 ;
  }
  else {
    print "num is $num sum is $sum\n" ;
    $sum += $num ;
    print "sum += num\n" ;
    print "num is $num sum is $sum\n" ;
    $sum += ($num * 1) + 0 ; 
    print "sum += (num * 1) + 0\n" ; 
    print "num is $num sum is $sum\n" ;
  }
}  

 
