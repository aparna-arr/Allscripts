#!/usr/bin/env perl
use warnings;
use strict;

my $warning = "
Warnings:
<col 1 bedfile> is the chr column of the bedfile
Lowmem: makes a bed file per chromosome. <chr>.tmp
Relies on UNIX grep, sort, cat.
Deletes all *.tmp in current dir. (!!!) 
Outfile: <input bed file>_sorted

";

my ($col1, $input) = @ARGV;
die "usage: $0 <col 1 bedfile> <bedfile>\n$warning" unless @ARGV == 2;

print $warning;

open (IN, "<", $col1) or die "Could not open $input\n";
my %chroms;

while (<IN>) {
  my $line = $_;
  chomp $line;
  if (!exists($chroms{$line})) {
    $chroms{$line} = "$line.tmp";
  }
}
close IN;

my $outfile = "$input\_sorted";
foreach my $chr (sort keys %chroms) {
  print "Chr $chr\n";
  `grep -w "$chr" $input > $chroms{$chr}`;
  `sort -k 2,2n $chroms{$chr} > sorted_$chroms{$chr}`;
  `cat sorted_$chroms{$chr} >> $outfile`;
}
`rm *.tmp`;
print "Outfile is $outfile\n";




