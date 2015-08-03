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
#my $SIG_BLOCKS = 23419; # count these beforehand! Numbers output from make_cache.pl
my $FALSE_NEG_CALLER = "/data/aparna/GA/fn_caller_0.report"; # 0.report from super stringent run 
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
open (FN, "<", $FALSE_NEG_CALLER) or die "Could not open $FALSE_NEG_CALLER\n";
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

my %stringent;
while (<FN>) {
  my $line = $_;
  chomp $line;
  if ($line =~ /#/) {
    next;
  }
  
  my ($chr, $start, $end) = $line =~ /^chr(.+)\tStochHMM\tPeak\t(\d+)\t(\d+)\t.+$/ ;
#  print "$chr\t$start\t$end\n";
  push(@{$stringent{$chr}}, {start=>$start, end=>$end});
}

close FN;

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

    if ($len < 50) {
      $fp += $len;
      next;
    }
#    my $totallen = 0;

    $index = binary_search($start, \@wig_chr, $index);
    
    while (exists($wig_chr[$index]{start}) && $wig_chr[$index]{start} + 9 <= $end) {
      if ($wig_chr[$index]{start} <= $start + 9) { # if the first 10 bp are > 20
        $first = 0;
      }
      elsif ($wig_chr[$index]{start} +9 >= $end - 9){ # the last 10 bp are > 20
        $last = 0;
      } 
#      print "$index\n";
#      if (!exists($wig_chr[$index]{value}))
#      {
#        if (!exists($wig_chr[$index]{start})) {
#        
#          die "!exists $index and start\n";
#        }
#        die "!exists $index\n";
#      
#      }
#      if ($wig_chr[$index]{value} > 2*$SCORE_THRESH) {
#        $used_sig_blocks++ ;
#      }
#      $totallen++; # keep track of number of elements
      $index++;
      $siglen++;
    }
#    if (!$totallen) {
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

my $total_str = 0;
my $non_fn = 0;

foreach my $chrom (keys %stringent) {
  my $fn_index = 0;
  for (my $j = 0 ; $j < @{$stringent{$chrom}}; $j++) {
    my $str_start = $stringent{$chrom}[$j]{start};
    my $str_end = $stringent{$chrom}[$j]{end};

    $fn_index = binary_search($str_start, \@{$called{$chrom}}, $fn_index);
    if (!exists($called{$chrom}[$fn_index]{start})) {
      last; 
    }
#    print "$called{$chrom}[$fn_index]{start}\t$called{$chrom}[$fn_index - 1]{start}\n";    
    if ($fn_index > 0 && $called{$chrom}[$fn_index - 1]{end} >= $str_start) {
      $fn_index--;
    }

    my $c_start = $called{$chrom}[$fn_index]{start};
    my $c_end = $called{$chrom}[$fn_index]{end}; 
#    print "$called{$chrom}[$fn_index]{start}\n";    

    $total_str += $str_end - $str_start;
#    die;
    while ($c_start <= $str_end && $c_end >= $str_start) {    
      if ($c_start <= $str_start) {
        if ($c_end >= $str_end) { 
          $non_fn += $str_end - $str_start;
        }
        else {
          $non_fn += $c_end - $str_start;
        }
      } 
      elsif ($c_start > $str_start) {
        if ($c_end > $str_end) {
          $non_fn += $str_end - $c_start;
        }
        else {
          $non_fn += $c_end - $c_start;
        }
      }
      $fn_index++;
      if ($fn_index >= @{$called{$chrom}}) {
        last;
      }
      $c_start = $called{$chrom}[$fn_index]{start};
      $c_end = $called{$chrom}[$fn_index]{end}; 
    }

  }
}

$fn = $total_str - $non_fn;
#$fn = $SIG_BLOCKS * 10 - $used_sig_blocks * 10;
$tn = $UNSIG_BLOCKS * 10 - $fp;

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
