#!/usr/bin/env perl
use warnings;
use strict;

my ($res, $peak) = @ARGV;
die "usage: $0 <restriction frag file> <peak file>\n" unless @ARGV == 2;
print "Assumes sorted files!\n";
open (OUT, ">", "$peak\_.adjusted") or die "Could not open outfile\n";

my %frags = read_in($res);
print "Done reading in restriction fragments\n";
my %peaks = read_in($peak);
print "Done reading in peaks\n";

my %adjust;

foreach my $chrom (keys %peaks) {
  my $start_index = 0;
  my $end_index = 0;
  print "Starting chr $chrom\n";

  for (my $i = 0; $i < @{$peaks{$chrom}}; $i++) {
    my $start = $peaks{$chrom}[$i]{start};
    my $end = $peaks{$chrom}[$i]{end};

    $start_index = binary_search($start, \@{$frags{$chrom}}, $start_index);
    $end_index = binary_search($end, \@{$frags{$chrom}}, $end_index);
  
    $adjust{$chrom}[$i]{start} = $frags{$chrom}[$start_index]{start};
    $adjust{$chrom}[$i]{end} = $frags{$chrom}[$end_index]{end};
  }
}

close OUT;

sub read_in {
  my $file = $_[0];
  my %hash;

  open (IN, "<", $file) or die "Could not open $file\n";

  while (<IN>) {
    my $line = $_;
    chomp $line;
    if ($line !~ /^chr/) {
      next;
    }
  
    my ($chr, $start, $end) = split(/\t/, $line);  
    push (@{$hash{$chr}}, {start=>$start, end=>$end});
  }

  close IN;

  return(\%hash);
}

sub binary_search {
  my $num = $_[0];
  my @indexes = @{$_[1]};
  my $min_index = $_[2];
  my $first = $min_index;
  my $last = @indexes - 1;
  my $middle = int (($last + $first) / 2);

  while ($first <= $last) {
    if ($indexes[$middle]{start} < $num) {
      $first = $middle + 1;
    }
    elsif ($indexes[$middle]{start} == $num) {
      last;
    }
    else {
      $last = $middle - 1;
    }
    $middle = int (($last + $first) / 2);
  }
  
#  if ($first > $last) {
#    if ($num - $indexes[$middle]{start} > 0) {
#      $middle++ ;
#    }
  }
  return($middle);
}
