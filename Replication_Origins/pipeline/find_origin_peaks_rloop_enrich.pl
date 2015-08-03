#!/usr/bin/env perl
use warnings;
use strict;

my ($drip, $dripc) = @ARGV;
die "usage: $0 <origins mapped DRIP> <origins mapped DRIPc>\n" unless @ARGV == 2;

my ($drip_ref, $drip_int_ref) = readin($drip);
my ($dripc_ref, $dripc_int_ref) = readin($dripc);

my @tmp = @{$drip_ref}; 
 
my (@sort_drip) = sort {$b->{val} <=> $a->{val}} @tmp;
my (@sort_dripc) = sort {$b->{val} <=> $a->{val}} @{$dripc_ref};

print "Intervals: DRIP
MAX $sort_drip[0]{val}
TOP $drip_int_ref->[2]
MED $drip_int_ref->[1]
LOW $drip_int_ref->[0]
";

print "Intervals: DRIPc
MAX $sort_dripc[0]{val}
TOP $dripc_int_ref->[2]
MED $dripc_int_ref->[1]
LOW $dripc_int_ref->[0]
";

# find top

my $count = 0;
my $index_rand;

for (my $i = 0; $i < int(@sort_drip/100); $i++) {

  $index_rand = int(rand(int(@sort_drip/100)));

  if ($dripc_ref->[$sort_drip[$index_rand]{index}]{val} >= $dripc_int_ref->[2]) {
    print "TOP: $sort_drip[$index_rand]{chr} $sort_drip[$index_rand]{start} $sort_drip[$index_rand]{end} drip_val $sort_drip[$index_rand]{val}\n";
    $count++;
  }

  if ($count == 10) {
    last;
  }
} 

$count = 0;

my $third = int(@sort_drip/20);

my @drip_third = @sort_drip[int(@sort_drip/100) .. $third];


for (my $j = 0; $j < @drip_third; $j++) {
  $index_rand = int(rand(@drip_third)); 
  
  if ($dripc_ref->[$drip_third[$index_rand]{index}]{val} >= $dripc_int_ref->[1]) {
    print "MED: $drip_third[$index_rand]{chr} $drip_third[$index_rand]{start} $drip_third[$index_rand]{end} drip_val $drip_third[$index_rand]{val}\n";
    $count++;
  } 
  
  if ($count == 10) {
    last;
  }
}

$count = 0;
my @drip_median = @sort_drip[int(@sort_drip / 4) .. @sort_drip-1];

for (my $k = 0; $k < @drip_median; $k++) {
  $index_rand = int(rand(@drip_median)); 
  
  if ($dripc_ref->[$drip_median[$index_rand]{index}]{val} <= $dripc_int_ref->[0]) {
    print "LOW: $drip_median[$index_rand]{chr} $drip_median[$index_rand]{start} $drip_median[$index_rand]{end} drip_val $drip_median[$index_rand]{val}\n";
    $count++;
  }    

  if ($count == 10) {
    last;
  }
} 

sub readin {
  my $file = $_[0];
  my @ar;  
  my @vals;

  open (IN, "<", $file) or die "could not open file $file: $!\n";
  while (<IN>) {
    my $line = $_;
    chomp $line;
    if ($line =~ /^chr/) {
      my ($chr, $start, $end, $val) = split(/\s+/, $line);
      my $size = @ar;
      push (@ar, {chr => $chr, start => $start, end => $end, val => $val, index => $size});
      push (@vals, $val);
    }
  }

  close IN;
  
  my @ints;

  my @sval = sort{$b <=> $a} @vals;
  $ints[2] = $sval[int(@vals / 100)]; # top 90 percent: high
  $ints[1] = $sval[int(@vals/20)]; # 3rd quartile: medium
  $ints[0] = $sval[int(@vals / 4)]; # median: low

  return (\@ar, \@ints);
}


