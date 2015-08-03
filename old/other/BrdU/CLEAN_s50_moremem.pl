#!/usr/bin/env perl
use warnings ;
use strict ;
use POSIX ;

my $warning = "
Warnings:
Lowmem: splits into chr\$chrom_file\$i.tmp
FIXME rm *.tmp is run!
All files MUST BE BEDGRAPH
Outfile is chr\$chr_s50outfile.txt 

";

my (@sfiles) = @ARGV ;
die "usage: $0 <S1 - S6 beds IN ORDER>\n$warning" unless @ARGV ;

print $warning;

if (@sfiles < 6) {
  die "You did not input 6 files!\n" ;
}

print "Splitting into temp files\n" ;
my %chrom_files = %{temp_files(\@sfiles)} ;
print "Done spliting\n" ;

foreach my $chrom (keys %chrom_files) {
  my ($start) = $chrom_files{$chrom}{start} ;
  my ($end) = $chrom_files{$chrom}{end} ;
  print "Start is $start end is $end\n" ;
  print "Starting read_in for chr $chrom\n" ;

  my (@svals) = @{read_in(\@{$chrom_files{$chrom}{files}}, $start, $end)} ;

  print "Done read_in for chr $chrom\n" ;
  print "Starting analyze for chr $chrom\n" ;

  my (@sfraction) = @{analyze(\@svals, $start)} ;

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

for (my $i = 0 ; $i < @inputfiles ; $i++) {
    open (IN, "<", $inputfiles[$i]) or die "Could not open $inputfiles[$i]\n" ;

    while (<IN>) {
      my $line = $_ ;
      chomp $line ;
      if ($line =~ /^track/) {
        next ;
      }
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
      $tempfiles{$chrom}{lines} = "" ; # undef the file from mem 
    }

  }

  return (\%tempfiles) ;
}

sub read_in {
  my @files = @{$_[0]} ;
  my $start_global = $_[1] ;
  my $end_global = $_[2] ;
  my @values ;

  for (my $i = 0 ; $i < @files ; $i++) {
    print "On file $i\n" ;
    open (IN, "<", $files[$i]) or die "Could not open $files[$i]\n" ;
    for (my $j = $start_global ; $j <= $end_global ; $j += 50000) {
      push (@{$values[$i]}, {start => $j , signal => 0}) ;
      my $index_value = @{$values[$i]} - 1 ;
      if ($i > 0) {
        $values[$i][$index_value]{signal} += $values[$i - 1][$index_value]{signal} ;
      }
    }
    while (<IN>) {
      my $line = $_ ;
      chomp $line ;
    
      my ($start, $end, $val) = $line =~ /^chr.+\t(\d+)\t(\d+)\t(.+)$/ ;
      my $index = index_binary_search(\@{$values[$i]}, $start) ;    
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
            $index ++ ;
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

sub index_binary_search {  
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
  my $start_global = $_[1] ;
  my @fracs ;
# @vals is $vals[SPHASE][50KB window]{signal}
  for (my $i = 0 ; $i < @{$vals[0]} ; $i++) { # @{$vals[0]} should be the same size for all $vals[i] ie it's the number of 50kb windows
    if ($vals[5][$i]{signal} == 0) { # ie if m_value == 0
      my $index_na = @fracs ;
      $fracs[$index_na]{start} = $start_global + $i * 50000 ; #may be wrong
      $fracs[$index_na]{percent} = "NA" ; 
      next ;
    }
    my $significant_signal = $vals[5][$i]{signal} / 2 ;
    my $outer = 5 ;
    for (my $n = 0 ; $n < @vals ; $n++) {
      if ($vals[$n][$i]{signal} > $significant_signal) {
        $outer = $n ;
        last ;
      }
    }
    #linear interpolation
    my ($slope, $x1) ;
  
    my $inner = $outer - 1 ;

    if ($inner == -1) {
      $slope = ( 0 - $vals[$outer][$i]{signal} ) / ( ( ($inner + 1) * 15 ) - ( ($outer + 1) * 15 ) ) ;
      $x1 = -1 * ($inner + 1) * 15 * $slope + 0 ;
    }
    else {
      $slope = ( $vals[$inner][$i]{signal} - $vals[$outer][$i]{signal} ) / ( ( ($inner + 1) * 15 ) - ( ($outer + 1 ) * 15 ) ) ;
      $x1 = -1 * ($inner + 1) * 15 * $slope + $vals[$inner][$i]{signal} ;
    }

    my $x = ($significant_signal - $x1) / $slope ;

    my $index = @fracs ;
  
    $fracs[$index]{start} = $start_global + $i * 50000 ;
    $fracs[$index]{percent} = $x ;
    if (!exists($fracs[$index]{start})) {
      print "!exists! $i\n" ;
    }
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
}




