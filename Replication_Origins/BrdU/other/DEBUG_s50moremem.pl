#!/usr/bin/env perl
use warnings ;
use strict ;
use POSIX ;

my (@sfiles) = @ARGV ;
die "usage: $0 <S1 - S6 beds IN ORDER>\n" unless @ARGV ;

if (@sfiles < 6) {
  die "You did not input 6 files!\n" ;
}

print "All files MUST BE BEDGRAPH\n" ;
print "Assumes no header\n" ;

print "Splitting into temp files\n" ;
my %chrom_files = temp_files(\@sfiles) ;
print "Done spliting\n" ;

foreach my $chrom (keys %chrom_files) {
  my ($start) = $chrom_files{$chrom}{start} ;
  my ($end) = $chrom_files{$chrom}{end} ;
  print "Starting read_in for chr $chrom\n" ;
  my (@svals) = read_in(\@{$chrom_files{$chrom}{files}}, $start, $end) ;
  print "Done read_in for chr $chrom\n" ;

  # m_val should be equal to sphase 6 value

  print "Starting analyze for chr $chrom\n" ;
  my (@sfraction) = analyze(\@svals) ;
  print "Done analyze for chr $chrom\n" ;
  print "Printing outfiles for chr $chrom\n" ;
  print_outfiles(\@sfraction, $chrom) ;
  print "Done printing outfiles for chr $chrom\n" ;
}
`rm *.tmp` ;
print "Script done!\n" ;

sub temp_files {
  my @inputfiles = @{$_[0]} ;
  my %tempfiles ;

# chromosomes SHOULD all be the same in all files, assuming this during read-in
  foreach my $i (0..scalar(@inputfiles)) {
    open (IN, "<", $inputfiles[$i]) or die "Could not open $inputfiles[$i]\n" ;

    while (<IN>) {
      my $line = $_ ;
      chomp $line ;

      my ($chr, $localstart, $localend) = $line =~ /^chr(.+)\t(\d+)\t(\d+)\t.+/ ; 
      $tempfiles{$chr}{lines} .= $line . "\n" ; # makes long string of all lines with that chr
      if (!exists($tempfiles{$chr}{start}) || $localstart < $tempfiles{$chr}{start}) {
        $tempfiles{$chr}{start} = $localstart ;    
      }  
      if (!exists($tempfiles{$chr}{end}) || $localend > $tempfiles{$chr}{end}) {
        $tempfiles{$chr}{end} = $localend ;   
      }
    }

    close IN ;

    foreach my $chrom (keys %tempfiles) {
      my $outfile = "chr$chrom\_file$i\.tmp" ;
      $tempfiles{$chrom}{files}[$i] = $outfile ; 
      open (OUT, ">", $outfile) or die "Could not open $outfile\n" ;
      print OUT "$tempfiles{$chrom}{lines}" ;
      close OUT ;
      %{$tempfiles{$chrom}{lines}} = () ; # undef the file from mem 
    }

  }

  return (\%tempfiles) ;
}

sub read_in {
  my @files = @{$_[0]} ;
  my $start = $_[1] ;
  my $end = $_[2] ;
  my @values ;

# CODE
  # @svals should be an array of arrays. 
    # ARRAY OF S phase (1 - 6)
      # ARRAY OF 50 kb window bp * val values
  # or switch depending on how messed up the loops are  
  # m_val should be equal to sphase 6 value

  foreach my $i (0..scalar(@files)) {
    open (IN, "<", $files[$i]) or die "Could not open $files[$i]\n" ;
    for (my $j = $start ; $j <= $end ; $j += 50000) {
      # Do something? index?
      $values[$i][@{$values[$i]}]{start} = $j ;
    }
    while (<IN>) {
      my $line = $_ ;
      chomp $line ;
    
      my ($start, $end, $val) = $line =~ /^chr.+\t(\d+)\t(\d+)\t(.+)$/ ;
  
      # binary search for nearest index?
      # need to deal with these cases :
      
      # --- | - START -- END ---| --- # case 1
      # --- | --- START --- | --- END # case 2
      # START --- | ------- | --- END # possible but not likely intermediate case
      # START --- | --- END --- | --- # case 3 end

      # Need to store ALL values in SOME window
      # maybe find window that contains start, then if END not in window shift window, etc, until END is in window, last window
# NOTE : @indexes is actually @values !!!
      # $index = BINARY_SEARCH $start, @indexes
      # IF END < $indexes[$index]{start} + 50000 # case 1 most likely 
        # STORE bp * val FOR $start -> $end
      # ELSE
        # WHILE (1) OR UNTIL END < $indexes[$index]{start} + 50000 
          # IF END > $indexes[$index]{start} + 50000
            # IF START > $indexes[$index]{start} # case 2  
              # STORE bp * val FOR $start -> $indexes[$index]{start} + 50000
            # ELSE # intermediate case
              # STORE bp * val FOR $indexes[$index]{start} -> $indexes[$index]{start} + 50000
            # $index += 50000 
          # ELSE # case 3 end
            # STORE bp * val FOR $indexes[$index]{start} -> $end
            # LAST (?)
      my $index = index_binary_search(\@{$values[$i]}, $start) ; # FIXME write this sub ## written not tested  
      if ($end < $values[$i][$index]{start} + 50000) {
        $values[$i][$index]{signal} += ($end - $start) * $val ;
      }
      else {
        while(1) { # FIXME CHANGE
          if ($end > $values[$i][$index]{start}) {
            if ($start > $values[$i][$index]{start}) {
              $values[$i][$index]{signal} += ($values[$i][$index]{start} + 50000 - $start) * $val ;
            }
            else {
              $values[$i][$index]{signal} += 50000 * $val ; 
            }
            $index += 50000
          }
          else {
            $values[$i][$index]{signal} += ($end - $values[$i][$index]{start}) * $val ;
            last ; # Because horrible while(1) loop
          }
        }
      }
    }
    close IN ;
  }

  return (\@values) ;  # array of S files then array of 50kb windows {start} and {signal}
}

sub index_binary_search { # FIXME write this!
  # for the read_in function's call to binary_search
  my @indexes = @{$_[0]} ; # $indexes{start} for start, end is $indexes{start} + 50kb
  my $num = $_[1] ;
  
  my $first = 0 ;
  my $last = @indexes - 1 ;
  my $middle = int ( ($last + $first) / 2 )  ; 

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
    $middle = int ( ($last + $first) / 2 )  ; 
  }
  if ($first > $last) {
    if ($num - $indexes[$middle]{start} < 0) {
      $middle++ ;
    }    
  } 
  return ($middle) ;
}

sub analyze {
  my @vals = @{$_[0]} ;
  my @fracs ;
# @vals is $vals[SPHASE][50KB window]{signal}
# CODE
  for (my $i = 0 ; $i < @{$vals[0]} ; $i++) { # @{$vals[0]} should be the same size for all $vals[i] ie it's the number of 50kb windows
    if ($vals[5][$i] == 0) { # ie if m_value == 0
      my $index_na = @fracs ;
      $fracs[$index_na]{start} = $vals[0][$i]{start} ; #may be wrong
      $fracs[$index_na]{percent} = "NA" ; 
      next ;
    }
    my $significant_signal = $vals[5][$i] / 2 ;
    my $outer = 5 ;
    for (my $n = 0 ; $n < @vals ; $n++) {
      if ($vals[$n][$i] > $significant_signal) {
        $outer = $n ;
        last ;
      }
    }
    #linear interpolation
    my ($slope, $x1) ;
  
    my $inner = $outer - 1 ;

    if ($inner == -1) {
      $slope = ( 0 - $vals[$outer][$i] ) / ( ( ($inner + 1) * 15 ) - ( ($outer + 1) * 15 ) ) ;
      $x1 = -1 * ($inner + 1) * 15 * $slope + 0 ;
    }
    else {
      $slope = ( $vals[$inner][$i] - $vals[$outer][$i] ) / ( ( ($inner + 1) * 15 ) - ( ($outer + 1 ) * 15 ) ) ;
      $x1 = -1 * ($inner + 1) * 15 * $slope + $vals[$inner][$i] ;
    }

    my $x = ($significant_signal - $x1) / $slope ;

    my $index = @fracs ;
  
    $fracs[$index]{start} = $vals[0][$i]{start} ;
    $fracs[$index]{percent} = $x ;
  }
  return (\@fracs) ;
}

sub print_outfiles {
  my @outvalues = @{$_[0]} ;
  my $chr = $_[1] ;

  my $outfile = "chr$chr\_s50outfile.txt" ;
  open (OUT, ">", $outfile) or die "Could not open $outfile\n" ;
  print "outfile is $outfile for chr $chr\n" ;

  for (my $m = 0 ; $m < @outvalues ; $m++) {
    print OUT "$outvalues[$m]{start}\t$outvalues[$m]{percent}\n" ;
    my $newend = $outvalues[$m]{start} + 49999 ;
    print OUT "$newend\t$outvalues[$m]{percent}\n" ;
  }
  close OUT ;
  # CODE
}






__END__

my @chromosomes ;

## WRAP EVERYTHING IN FUNCTIONS ##

# $chromosomes{chr}[sphase1 mini file] etc
# what if chr is not in all sphase files?
# do a NULL if {chr} is not = 6
for (my $i = 0 ; $i < @sfiles ; $i++) {
  open (IN, "<", $sfiles[$i]) or die "Could not open $sfilesp[$i]\n" ;
  while (<IN>) {
    my $line = $_ ;
    chomp $line ;

    my ($chr) = $line =~ /^chr(.+)\t.+/ ;
    $chromosomes{$chr}[$i] = "$chr-$i.tmp" ; # MAY CRASH
    # should I .= in a variable or >> to the temp file? (look at metaplot script)
     
  }    

}
