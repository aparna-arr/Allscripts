#!/usr/bin/env perl
use warnings;
use strict;

my ($mafile, $mapfile) = @ARGV;
die "usage: $0 <MAnorm file> <Mapped file>\n" unless @ARGV;

open (MA, "<", $mafile) or die "Could not open $mafile\n";
open (MAP, "<", $mapfile) or die "Could not open $mapfile\n";
open (OUT, ">", "recolor_outfile.bed");

my %ma;
while (<MA>) {
  my $line = $_;
  chomp $line;
  my ($chr, $start, $end, $trash) = split(/\s+/, $line);
  $ma{$chr}{$start} = $end;
}
close MA;

while (<MAP>) {
  my $line = $_;
  chomp $line;
  my ($chr, $start, $end, $trash) = split(/\s+/, $line);
  if (exists($ma{$chr}{$start}) && $end == $ma{$chr}{$start}) {
    print OUT "$line\n";
  }
}

close MAP;
close OUT;
print "Outfile is recolor_outfile.txt\n";


