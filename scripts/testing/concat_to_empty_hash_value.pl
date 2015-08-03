#!/usr/bin/env perl
use warnings;
use strict;

my %hash = (
  val1 => "hello",
  val2 => "hello2",
  val3 => "hello3"
);

foreach my $key (keys %hash) {
  print "0) Key $key is value $hash{$key}\n";
}

$hash{val1} .= " world";

foreach my $key (keys %hash) {
  print "1) Key $key is value $hash{$key}\n";
}

$hash{val4} .= "hello4";

foreach my $key (keys %hash) {
  print "2) Key $key is value $hash{$key}\n";
}
