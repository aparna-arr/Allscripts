#!/usr/bin/env perl
use warnings ;
use strict ;
use POSIX ;

my ($start, $end, @sphase) = @ARGV ;
die "usage: $0 <start_pos> <end_pos> <s1 - s6 files for 1 chr>\n" unless @ARGV ;


if (@sphase < 6) {
  die "You did not input correct files!\n" ;
}

print "ONE CHR ONLY\n" ;

my $length = $end - $start ;
print "length is $length\n" ;
my $inital = ( $end - $start ) / 50000 ;
my $func_end = floor($inital) * 50000 + $start ;
print "Func end : $func_end\n" ;
my @fracs ;

for (my $i = $start ; $i < $func_end ; $i += 50000) {
  # This is the 50KB window that all the calculations take place
  my @s;
  my $m_value = 0 ;
  my $infiniteloop = ($i - $start) / 50000 ;
  if ($infiniteloop % 10 == 0) {
    print "FOR LOOP $infiniteloop\n" ;
  }
  for (my $j = 0 ; $j < @sphase ; $j++ ) {

    open (IN, "<", $sphase[$j]) or die "Could not open $sphase[$j]\n" ;
    $s[$j] += $m_value ;
    while(<IN>) {
      my $line = $_ ;
      chomp $line ;
      my ($startnum, $endnum, $val) = $line =~ /^chr.+\t(.+)\t(.+)\t(.+)/ ;
      my $plus = $i + 50000 ;
      if (($startnum >= $i) && ($endnum <= $plus)) {
        $s[$j] += ( $endnum - $startnum ) * $val ;
      }

      elsif (($startnum < $i) && ($endnum <= $plus && $endnum > $i)) {
        $s[$j] += ($endnum - $i) * $val ;
      }
     
      elsif (($endnum > $plus) && ($startnum >= $i && $startnum < $plus)) {
        $s[$j] += ($plus - $startnum) * $val ;
      }
      elsif ($startnum < $i && $endnum > $plus) {
        $s[$j] += ($plus - $i) * $val ;
      }
    }   
    close IN ;

#    $s[$j] /= 50000 ; # This assumes that the ABSOLUTE start and end is in all the files otherwise error OR maybe not error. Leave this. Or ... commenting for now b/c avg is not important
    $m_value = $s[$j] ;
  }
  if ($m_value == 0) {
    my $index_na = @fracs ;
    $fracs[$index_na]{start} = $i ;
    $fracs[$index_na]{percent} = "NA" ; 
    next ;   
  }
  my $significant_signal = $m_value / 2 ;

  # do binary search ? But only 6 elements in array
  my $outer = 5 ; #should be last element
  for (my $n = 0 ; $n < @s ; $n++) {
    if ($s[$n] > $significant_signal) {
      $outer = $n ;
      last ;
    }
  } 

#Linear interpolation

  my ($slope, $x1) ;

  my $inner = $outer - 1 ;
  if ($inner == -1) {
#    print "FIXME!\n" ;
#    die "inner is $inner! sig_signal is $significant_signal s[outer] is $s[$outer] DIE\n" ;
    $slope = ( 0 - $s[$outer] ) / ( ( ($inner + 1 ) * 15) - ( ($outer + 1 )* 15) ) ;
    $x1 = -1 * ($inner + 1) * 15 * $slope + 0 ;
  }
  else {
    $slope = ( $s[$inner] - $s[$outer] ) / ( ( ($inner + 1 ) * 15) - ( ($outer + 1 )* 15) ) ;
    $x1 = -1 * ($inner + 1) * 15 * $slope + $s[$inner] ;
  }

  if ($slope == 0) {
# CENTROMERES WILL HAVE NO SIGNAL
    print "FIXME!\n" ;
    print "Slope is $slope somehow! outer is $outer inner is $inner DIE\n" ;
    die "inner is $inner! sig_signal is $significant_signal s[outer] is $s[$outer] DIE\n" ;
  }

#  print "slope is $slope\n" ;
  my $x = ($significant_signal - $x1 ) / $slope ; # PERCENT OF S PHASE

  my $index = @fracs ;
  $fracs[$index]{start} = $i ;
  $fracs[$index]{percent} = $x ;    
#  print "inner is $inner outer is $outer slope is $slope x1 is $x1 x is $x index is $index\n" ;
#  print "FOR LOOP DONE\n" ; 
}

# now need to print out s50 profile and smooth etc with gaussian
# don't need to print out every bp since 50kb have the same val
# print out start and end - 1 (otherwise will get overwritten with next start)

my $outfile = "s50outfile.txt" ;
open (OUT, ">", $outfile) or die "Could not open outfile\n" ;
print "outfile is $outfile, in format [pos]<TAB>[val]\n" ;

for (my $m = 0 ; $m < @fracs ; $m++) {
#  print "m is $m\n" ;
#  print "start is $fracs[$m]{start} percent is $fracs[$m]{percent}\n" ;
  print OUT "$fracs[$m]{start}\t$fracs[$m]{percent}\n" ;
  my $newend = $fracs[$m]{start} + 49999 ;
  print OUT "$newend\t$fracs[$m]{percent}\n" ;
}

close OUT ;

print "script done! now need to smooth and find inflection points\n" ;
