#!/usr/bin/env perl
use warnings ;
use strict ;

get_input() ;
# for no score thresh, input 0 for that field

sub get_input {
  my (@input) = @ARGV ;
  die "\nusage: $0 <pacbio sam file> -[options]\noptions:\n\ti : initial sliding window\n<pacbio sam file> -i <window size> <shift size> <score threshold>\n\n\tr : real run: call regions\n<pacbio sam file> -r <min region length / window size> <shift> <score threshold>\n\n" unless @ARGV ;

  my $inputstr = join(" ", @input) ;

  if ($inputstr !~ /^.+\s-[ir](\s.+){3}$/) {
    die "Incorrect input! Check usage. String :\n$inputstr\n" ; 
  }
  else {
    my %reads = %{read_in($input[0])} ;

    if ($input[1] eq "-i") {
      initial_sliding_window($input[2], $input[3], $input[4], \%reads, $input[0]) ;
    }
    else {
      call_regions($input[2], $input[3], $input[4], \%reads, $input[0]) ;
    }

  }

}

sub read_in {
  my $file = $_[0] ;
  
  my %reads ;

  open (IN, "<", $file) or die "Could not open $file\n" ;

  while (<IN>) {
    my $line = $_ ;
    chomp $line ;

    if ($line =~ /^@/) {
      next ;
    }

    my @fields = split(/\t/, $line) ;
    my ($id) = $fields[0] =~ /\/(\d+)\/ccs$/ ;

    my ($roughstr) = $fields[13] =~ /..:.:(.+)$/;
    $roughstr =~ tr/[A-Z]/N/ ; # nonconverted
    $roughstr =~ tr/[a-z]/C/ ; # converted
#    print "$roughstr\n" ;    
    my $start = $fields[3] ;

    $reads{$id}{start} = $start - 1 ; #pos 1 == 0
    $reads{$id}{string} = $roughstr ;
  }  

  return \%reads ;
}

sub initial_sliding_window {
  my $window = $_[0] ;
  my $shift = $_[1] ;
  my %reads = %{$_[3]} ;
  my $filename = $_[4] ;

  my %scores ;

  foreach my $read (keys %reads) {
    for (my $i = 0 ; $i <= 1800 - $window; $i += $shift) { # 2000 is placeholder for plasmid size
      if ($i < $reads{$read}{start}) {
        next ;
      }
      if ($i + $window > length($reads{$read}{string}) + $reads{$read}{start}) {
        last ;
      }
      my $str = substr($reads{$read}{string}, $i - $reads{$read}{start}, $window - 1) ;
      my $score = calc_score($str) ;
      $scores{($i + $window) / 2}{score} = $score ;
      $scores{($i + $window) / 2}{reads} ++ ;
    }
  }
  open (OUT, ">", $filename . "_OUT.txt") or die "Could not open outfile\n";
  foreach my $pos (sort {$a<=>$b} keys %scores) {
    if ($scores{$pos}{reads} > 0) { 
      print OUT "$pos\t" . $scores{$pos}{score}/$scores{$pos}{reads} . "\n" ; 
    }
  }
}

sub call_regions {
  my $window = $_[0] ;
  my $shift = $_[1] ;
  my $score = $_[2] ;
  my %reads = %{$_[3]} ;
  my $filename = $_[4] ;
  my $prev_start = 0 ;
  my %significant ;

  foreach my $read (keys %reads) {
    for (my $i = 0 ; $i <= 1800 - $window; $i += $shift) { # 2000 is placeholder for plasmid size
      if ($i < $reads{$read}{start}) {
        next ;
      }
      if ($i + $window > length($reads{$read}{string}) + $reads{$read}{start}) {
        last ;
      }
      my $str = substr($reads{$read}{string}, $i - $reads{$read}{start}, $window - 1) ;
      my $calc_score = calc_score($str) ;
      
      if ($calc_score >= $score) {
        if (!exists($significant{$read})) {
          $significant{$read}[0]{start} = $i - $reads{$read}{start} ;
          $significant{$read}[0]{end} = $i - $reads{$read}{start} + $window ;
        }
        elsif ($i - $shift == $prev_start){
          $significant{$read}[@{$significant{$read}}-1]{end} = $i - $reads{$read}{start} + $window ;
        }
        else {
          push(@{$significant{$read}}, {start => $i - $reads{$read}{start}, end => $i - $reads{$read}{start} + $window}) ; 
        }

        $prev_start = $i ;
      }
    }
  }
  
  open(OUT, ">", $filename . "_OUT.txt") or die "Could not open outfile\n" ;

  foreach my $read (keys %significant) {
    for (my $i = 0 ; $i < @{$significant{$read}} ; $i++) {
      print OUT "$read\t$significant{$read}[$i]{start}\t$significant{$read}[$i]{end}\t" . length($reads{$read}{string}) . "\n" ;
    }
  }
}

sub calc_score {
  my $str = $_[0] ;

  my $len = length($str) ;
  my $conv = $str =~ tr/C// ; 
  my $unconv = $str =~ tr/N// ;
#  my $score = ($conv - $unconv)/$len * 100 ; # gives a % 
#  my $score = ($conv/$len * 100) / ($unconv/$len * 100) ;
  my $score = ($conv - $unconv) / $len ;
  if ($len == 0) {
    die "Length of substr is 0!\n" ;
  }
  return $score ;
}
