#!/usr/bin/env perl
use warnings ;
use strict ;

my ($seq, $origins) = @ARGV ;
die "usage: $0 <RNA seq bed> <origin peakfile>\n" unless @ARGV == 2 ;
print "Assumes all files are sorted! Otherwise error.\n" ;
print "sort -k1,1 -k2,2n unsorted.bed > sorted.bed\n" ;
open (ORI, "<", $origins) or die "Could not open $origins\n" ;

my %peaks ;

while (<ORI>) {
  my $line = $_ ;
  chomp $line ;
  
  next if $line =~ /^track/ ;
  my ($chr, $start, $end) = split (/\t/, $line) ;

  push (@{$peaks{$chr}}, {pos => [$start, $end], count => 0}) ; 
}
close ORI ;
print "Done with $origins\n" ;
open (SEQ, "<", $seq) or die "Could not open $seq\n" ;

my $printchr = "INIT" ;
#my $mark = 0 ;
while(<SEQ>) {
  my $line = $_ ;
  chomp $line ;
  
  my ($chr, $start, $end, $count) = split(/\t/, $line) ;
  
  if (!exists($peaks{$chr})) {
    next ;
  }
  if ($chr !~ /$printchr/) {
    $printchr = $chr ;
    print "$printchr\n" ;
  }
#  for (my $i = $mark ; $i < @{$peaks{$chr}} ; $i++) {
  for (my $i = 0 ; $i < @{$peaks{$chr}} ; $i++) {
  # start between $peaks_start && $peaks_end
    if ($start >= $peaks{$chr}[$i]{pos}[0] && $start <= $peaks{$chr}[$i]{pos}[1]) { 
    # end could be anywhere
      if ($end <= $peaks{$chr}[$i]{pos}[1]) { 
      # start and end between $peaks_start and $peaks_end
        $peaks{$chr}[$i]{count} += $count * ($end - $start) ;
      }    
      else { 
      # $end is > $peaks_end
        $peaks{$chr}[$i]{count} += $count * ($peaks{$chr}[$i]{pos}[1] - $start) ;
      }
    }  
    # end between $peaks_start && $peaks_end and start < $peaks_start
    elsif ($end <= $peaks{$chr}[$i]{pos}[1] && $end >= $peaks{$chr}[$i]{pos}[0]) { 
# start < $peaks .. start
      $peaks{$chr}[$i]{count} += $count * ($end - $peaks{$chr}[$i]{pos}[0]) ;
    }
    else { 
# start and end both not between $peaks_start and $peaks_end
      if ($start < $peaks{$chr}[$i]{pos}[0] && $end > $peaks{$chr}[$i]{pos}[1]) { 
# start is less than $peaks_start and end is greater than $peaks_end
        $peaks{$chr}[$i]{count} += $count * ($peaks{$chr}[$i]{pos}[1] - $peaks{$chr}[$i]{pos}[0]) ;
      }
      elsif ($start < $peaks{$chr}[$i]{pos}[0] && $end < $peaks{$chr}[$i]{pos}[0] ) { 
# if start and end are both less than $peaks_start
#        $mark = $i ;
#        print "$mark\n" ;
#        print "$i\n" ;
        last ;
      }
      else { 
# start and end are both greater than $peaks_end
        next ;
      }
    }
  } # count is added for each peak overlapping with line
} # done storing sums of counts in each peak 

close SEQ ;
print "Printing outfile\n" ;
open (OUT, ">", "RNAseq_peak_avg_output.bed") ;

foreach my $chrom (keys %peaks) { # averages for each peak bp and prints
  for (my $j = 0 ; $j < @{$peaks{$chrom}} ; $j++) {
    $peaks{$chrom}[$j]{count} /= ($peaks{$chrom}[$j]{pos}[1] - $peaks{$chrom}[$j]{pos}[0]) ;
    print OUT "$chrom\t$peaks{$chrom}[$j]{pos}[0]\t$peaks{$chrom}[$j]{pos}[1]\t$peaks{$chrom}[$j]{count}\n"
  }
}

close OUT ;
