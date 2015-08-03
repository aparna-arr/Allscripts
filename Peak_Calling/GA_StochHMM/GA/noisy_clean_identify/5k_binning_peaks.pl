#!/usr/bin/env perl
use warnings ;
use strict ;
use POSIX ;

my ($wigfile) = @ARGV;
#my (@sfiles) = @ARGV ;
#die "usage: $0 <S1 - S6 beds IN ORDER>\n" unless @ARGV ;
die "usage: $0 <one chr ordered variableStep wig file>\n" unless @ARGV ;

#if (@sfiles < 6) {
#  die "You did not input 6 files!\n" ;
#}

#print "All files MUST BE BEDGRAPH\n" ;

#print "Splitting into temp files\n" ;
#my %chrom_files = %{temp_files(\@sfiles)} ;
#print "Done spliting\n" ;

#foreach my $chrom (keys %chrom_files) {
  my ($wig_ref, $start, $end) = read_in_wig($wigfile);
  my @wig = @{$wig_ref};
#  print "Start is $start end is $end\n" ;
#  print "$wig[0]{start}\n";
#  print "Starting read_in for chr $chrom\n" ;

  my (@vals) = @{read_in(\@wig, $start, $end)} ;

#  print "Done read_in for chr $chrom\n" ;
#  print "Starting analyze for chr $chrom\n" ;

#  my (@sfraction) = @{analyze(\@svals, $start)} ;

#  print "Done analyze for chr $chrom\n" ;
#  print "Printing outfiles for chr $chrom\n" ;
  print "Printing outfile\n" ;

#  print_outfiles(\@sfraction, $chrom) ;
  print_outfile(\@vals) ;
  
#  print "Done printing outfiles for chr $chrom\n" ;
  print "Done printing outfile\n" ;
#}
#`rm *.tmp` ;
print "Script done!\n" ;

sub read_in_wig {
  my $wig = $_[0];
  my @wigvals;
  my $start = -1;
  my $end;

  open (IN, "<", $wig) or die "Could not open $wig\n";
  my ($chr, $span);
  while (<IN>) {
    my $line = $_;
    chomp $line ;

    if ($line =~ /\#/ | $line =~ /^track/) {
      next;
    }

    if ($line =~ /^variableStep/) {
      ($chr, $span) = $line =~ /^variableStep\schrom=chr(.+)\sspan=(.+)$/;
    }
    elsif ($line =~ /\d+\t\d+/) {
      my ($pos, $val) = $line =~ /(\d+)\t(\d+)/;
      if ($start == -1) {
        $start = $pos;
      }
      
      $end = $pos + $span; # assumes ordered wig file
      push(@wigvals, {start => $pos, end => $pos + $span, val => $val});
#      print "$wigvals[@wigvals - 1]{end}\n";
    }
    else {
      die "unrecognized line in wig file : $line\n";
    }
  } 
  return(\@wigvals, $start, $end);
}

sub read_in {
  my @wig = @{$_[0]};
#  my @files = @{$_[0]} ;
  my $start_global = $_[1] ;
  my $end_global = $_[2] ;
  my @values ;

#  print "$wig[0]{start}\n";
#  for (my $i = 0 ; $i < @files ; $i++) {
#    print "On file $i\n" ;
#    open (IN, "<", $files[$i]) or die "Could not open $files[$i]\n" ;
    for (my $j = $start_global ; $j <= $end_global ; $j += 5000) {
      push (@values, {start => $j , signal => 0}) ;
#      my $index_value = @values - 1 ;
#      if ($i > 0) {
#        $values[$i][$index_value]{signal} += $values[$i - 1][$index_value]{signal} ;
#      }
    }
#    while (<IN>) {
#      my $line = $_ ;
#      chomp $line ;
    
#      my ($start, $end, $val) = $line =~ /^chr.+\t(\d+)\t(\d+)\t(.+)$/ ;
    for (my $i = 0; $i < @wig ; $i++) {
      if ($i % 1000 == 0) {
        print "On Loop $i\n";
      }

      my $start = $wig[$i]{start};  
      my $end = $wig[$i]{end};
      my $val = $wig[$i]{val};
      my $index = index_binary_search(\@values, $start) ;    
      if ($end < $values[$index]{start} + 5000) {
        $values[$index]{signal} += ($end - $start) * $val ;
      }
      else {
        while(1) { # FIXME CHANGE
          if ($end > $values[$index]{start}) {
            if ($start > $values[$index]{start}) {
              $values[$index]{signal} += ($values[$index]{start} + 5000 - $start) * $val ;
            }
            else {
              $values[$index]{signal} += 5000 * $val ; 
            }
            $index ++ ;
          }
          
          else {
            $values[$index]{signal} += ($end - $values[$index]{start}) * $val ;
            last ; # Because horrible while(1) loop
          }
        }
      }
    }
#    close IN ;
#  }

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

sub print_outfile {
  my @outvalues = @{$_[0]} ;

  my $outfile = "5k_binning_outfile.txt" ;
  open (OUT, ">", $outfile) or die "Could not open $outfile\n" ;
  print "outfile is $outfile\n" ;

  for (my $m = 0 ; $m < @outvalues ; $m++) {
    print OUT "$outvalues[$m]{start}\t" . $outvalues[$m]{signal} / 5000 . "\n" ;
    my $newend = $outvalues[$m]{start} + 4999 ;
    print OUT "$newend\t" . $outvalues[$m]{signal} / 5000 . "\n" ;
  }
  close OUT ;
}




