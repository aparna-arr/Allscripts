#!/usr/bin/env perl
use warnings ;
use strict ;
use Cache::FileCache;

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
# need to define $cache somewhere
my $WIGFILE = "drip_wig_chr8"; # SET TO NAME OF WIG IN CACHE
my $SCORE_THRESH = 20; # Set to min score/height for a peak
my $SIG_BLOCKS = 23419; # count these beforehand! Numbers output from make_cache.pl
my $UNSIG_BLOCKS = 2569079; 
#is this correct syntax?
my $cache = new Cache::FileCache();
$cache -> set_cache_root("cache") ; # Set cache root here

my ($name) = $gff =~ /^(\d+)/ ;
my ($tp, $fp, $fn, $tn) ;

open (IN, "<", $gff) or die "Could not open $gff\n";

my %called; # stochhmm called peaks

while(<IN>) {
  my $line = $_;
  chomp $line ;

  if ($line =~ /#/) { # skip header line
    next ;
  }

  my ($chr, $start, $end) = $line =~ /^chr(.+)\t.+\t.+\t(\d+)\t(\d+)\t.+$/;
  push(@{$called{$chr}}, {start =>$start, end => $end}); #FIXME check this makes an array
}

close IN;

my $used_sig_blocks; # used significant blocks score > 2*thresh
#my $sig_blocks; # total significant blocks score > 2*thresh
#my $unsig_blocks; # total not significant blocks score < thresh
foreach my $chrom (keys %called) {
  my $wig_chr_ref = $cache -> get("$WIGFILE\.$chrom.cache");
  my @wig_chr = @{$wig_chr_ref}; # should be sorted

  my $min_index = 0;
  for(my $i = 0; $i < @{$called{$chrom}}; $i++) {
    # binary search to find index of start
    # wig_start > called_start, wig_end < called_end
    # if no blocks are identified, peak is a false pos
    my $index = binary_search($called{$chrom}[$i]{start}, \@wig_chr, $min_index);
    if ($wig_chr[$index]{start} + 9 > $called{$chrom}[$i]{end}) {
      next ; # return fp somehow
      #means peak is <10bp
    }
  
    while ($wig_chr[$index]{start} + 9 <= $called{$chrom}[$i]{end}) {
    # store score of each block IN A HASH
      $called{$chrom}[$i]{vals}{$index} = $wig_chr[$index]{value}; 
      $called{$chrom}[$i]{hashlen}++; # keep track of number of elements
#      print "$index\n";
      # faster than evaluating hash keys though that is not bad either
    # throw out lower indexes for good because sorted
      $min_index++;
      $index++;
      if ($wig_chr[$index]{value} > 2*$SCORE_THRESH) {
        $used_sig_blocks++ ;
      }
    }
    my ($num, $top);
    $num = int(($called{$chrom}[$i]{hashlen} + 1) / 2) ; 
    $top = $num ;
    my $avg;
    
#    for (my $j = 0; $j < @wig_chr; $j++) {
#      if ($wig_chr[$j]{value} > 2 * $SCORE_THRESH) {
#        $sig_blocks++;
#      }
#      elsif ($wig_chr[$j]{value} < $SCORE_THRESH) {
#        $unsig_blocks++;
#      }
#    }
  
    # sort scores hash
    foreach my $val (sort{$a<=>$b} values %{$called{$chrom}[$i]{vals}}) {
      if (!$top) {
        last;
      }
    
      $avg += $val; #check this!
      $top--; # strange way of doing this
    }  
  
    # take avg of top 50%
    $avg /= $num;

    # return / set a variable to declare if tp fp 
    if ($avg < $SCORE_THRESH) {
      # return / set a var to fp
      $fp += $called{$chrom}[$i]{end} - $called{$chrom}[$i]{start}; 
    }
    else {
      # return / set a var to tp
      $tp += $called{$chrom}[$i]{end} - $called{$chrom}[$i]{start}; 
    }
  }   
}

#$fn = $sig_blocks - $used_sig_blocks;
$fn = $SIG_BLOCKS - $used_sig_blocks;
#$tn = $unsig_blocks - $fp;
$tn = $UNSIG_BLOCKS - $fp;

print "$name,$tp,$tn,$fp,$fn";


#my $index = binary_search($called{$chrom}[$i]{start}, \@wig_chr, $min_index);
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
