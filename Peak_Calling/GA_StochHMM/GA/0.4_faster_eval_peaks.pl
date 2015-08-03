#!/usr/bin/env perl
use warnings ;
use strict ;
use Cache::FileCache;

# need to implement an index for both the wig and this gff file
# currently both eval scripts for peaks take ~9.5 mins for chr8. 

# script to replace evaluate_report.pl for use with GA stochhmm
# expects a stochhmm gff file
# expects only two states, only one of which is in the gff file
# aka only peaks listed
# requires the use of a pre-set cache containing a wig file
# wig file should be span=10
# expects everything to be sorted
# expects wig file has all chrs in bed/fasta files given to stochhmm.

my ($gff, $threshold) = @ARGV ;
die "usage: $0 <stochhmm gff file> <threshold>\n" unless @ARGV == 2;
# going to ignore threshold since using a gff file with only significant regions listed
my $WIGFILE = "drip_wig_chr8"; # SET TO NAME OF WIG IN CACHE
my $SCORE_THRESH = 20; # Set to min score/height for a peak
my $SIG_BLOCKS = 23419; # count these beforehand! Numbers output from make_cache.pl
my $UNSIG_BLOCKS = 2569079; 
my $cache = new Cache::FileCache();
$cache -> set_cache_root("/data/aparna/GA/cache") ; # Set cache root here

my ($name) = $gff =~ /^(\d+)/ ;
if (!`wc -l $gff`){
  die "report file empty!";
}
my ($tp, $fp, $fn, $tn) ;
$fp = 0;
$tp = 0;
$fn = 0;
$tn = 0;
open (IN, "<", $gff) or die "Could not open $gff\n";
my %called; # stochhmm called peaks

while(<IN>) {
  my $line = $_;
  chomp $line ;

  if ($line !~ /^chr/) {
    next ;
  }

  my ($chr, $start, $end) = $line =~ /^chr(.+)\t.+\t.+\t(\d+)\t(\d+)\t.+$/;
  push(@{$called{$chr}}, {start =>$start, end => $end});  
}

close IN;

my $used_sig_blocks; # used significant blocks score > 2*thresh

foreach my $chrom (keys %called) {
  my $wig_chr_ref = $cache -> get("$WIGFILE\.$chrom.cache");
  my @wig_chr = @{$wig_chr_ref}; # should be sorted
  my $index = 0;
  for(my $i = 0; $i < @{$called{$chrom}}; $i++) {
    my $end = $called{$chrom}[$i]{end} ;
    my $start = $called{$chrom}[$i]{start} ;
    my $len = $end - $start ;
    my $siglen = 0;

    my $first = 1;
    my $last = 1;

    if ($len < 300) {
      $fp += $len;
      next;
    }

    $index = binary_search($start, \@wig_chr, $index);
    
    while (exists($wig_chr[$index]{start}) && $wig_chr[$index]{start} + 9 <= $end) {
      if ($wig_chr[$index]{start} <= $start + 19) { # if the first 10 bp are > 20
        $first = 0;
      }
      elsif ($wig_chr[$index]{start} + 9 >= $end - 19){ # the last 10 bp are > 20
        $last = 0;
      } 
      if ($wig_chr[$index]{value} > 2*$SCORE_THRESH) {
        $used_sig_blocks++ ;
      }
      $index++;
      $siglen++;
    }
    if (!$siglen) {
      $fp += $len ;       
    }
    elsif ($siglen*10 / ($end - $start) >= .5 && $first && $last) {
      $tp += $len ;        
    # tp if 50% of the peak is significant AND the first 10bp and the last 10 bp do not contain a significant block
    }
    else {
      $fp += $len ;        
    }
  }   
}

$fn += $SIG_BLOCKS * 10 - $used_sig_blocks * 10;
$tn = $UNSIG_BLOCKS * 10 - $fp;

print "$name,$tp,$tn,$fp,$fn";

sub binary_search {
  my $num = $_[0] ;
  my @indexes = @{$_[1]} ;
  my $min_index = $_[2] ;
  my $first = $min_index ;
  my $last = @indexes - 1 ;
  my $middle = int (($last + $first )/2) ;

  while ($first <= $last) {
    if ($indexes[$middle]{start} < $num) {
      $first = $middle + 1 ;
    }
    elsif ($indexes[$middle]{start} == $num) {
      last ;
    }
    else {
      $last = $middle - 1 ;
    }
    $middle = int (($last + $first)/2) ;
  }

  if ($first > $last) {
    if ($num - $indexes[$middle]{start} > 0) {
      $middle++ ;
    } 
  }
    return ($middle) ; 
}
