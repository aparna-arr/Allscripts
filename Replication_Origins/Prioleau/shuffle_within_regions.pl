#!/usr/bin/env perl
use warnings;
use strict;

my $warning = "
Warnings:
Expects the input bed to be shuffled on to be completely valid. Gaps should already be removed.
Assumes the regions to be shuffled to be COMPLETELY contained within the regions to be shuffled on.
Assumes sorted bed files. Binary search used!
Allows shuffled regions to overlap, and original configuration may be reproduced. This is NOT an ideal shuffling script, but given enough runs it should be okay.
";

my ($regions_file, $shuffle_file, $runs, $intersect, $outfile) = @ARGV;
die "usage: $0 <file to be shuffled on> <file to be shuffled> <number of runs> <file to be intersected> <outfile>\n$warning" unless @ARGV;

my $regions = read_in($regions_file);
my $shuffle = read_in($shuffle_file);

shuffle($regions, $shuffle, $runs, $intersect, $outfile);

#cannot do for chr as outer loop, or else outfile printout is wrong
 
sub read_in {
  my $file = $_[0];
  my %hash;

  open (IN, "<", $file) or die "Could not open $file\n";

  while(<IN>) {
    my $line = $_;
    chomp $line;

    my @line_elements = split(/\s+/, $line);
  
#this may wrong
    push(@{$hash{$line_elements[0]}}, ($line_elements[1], $line_elements[2]));
  }

  close IN;

  return(\%hash);
}

sub shuffle {
  my %regions = %{$_[0]};
  my %shuffle = %{$_[1]};
  my $num_runs = $_[2];
  my $intersect = $_[3];
  my $outfile = $_[4];

  print "\ndebug: shuffle(): print 1\n";

  for (my $i = 0; $i < $num_runs; $i++) {
    my %new_pos;
    foreach my $chr (keys %shuffle) {
      my $s = 0;

      print "\ndebug: shuffle(): print 2\n";
      print "\ndebug: shuffle(): shuffle{chr}{s} : [$shuffle{$chr}[$s]]\n";

      my $index = binary_search($shuffle{$chr}[$s],\@{$regions{$chr}});
      for (my $j = $index; $j < @{$regions{$chr}}; $j++) {
        while ($shuffle{$chr}[$s][0] < $regions{$chr}[$j][1]) {
          #shuffle position, store
          my $shuffle_len = $shuffle{$chr}[$s][1] - $shuffle{$chr}[$s][0] ;
          my $adj_region_len = $regions{$chr}[$j][1] - $regions{$chr}[$j][0] - $shuffle_len ;
          my $start = int(rand($adj_region_len)) + $regions{$chr}[$j][0] ;  
          my $end = $start + $shuffle_len ;

          push(@{$new_pos{$chr}}, ($start, $end)) ;
          $s++ ;
        } # while        
      } # for
      # sort within chr
      @{$new_pos{$chr}} = sort {$a->[0]<=>$b->[0]} @{$new_pos{$chr}} ; # probably wrong syntax
    } # foreach

    open (TMP, ">", "$i\.tmp");
    # sort chrs
    foreach my $chrom (sort keys %new_pos) {
      for (my $n = 0; $n < @{$new_pos{$chrom}}; $n++) {
        print TMP "$chrom\t$new_pos{$chrom}[0]\t$new_pos{$chrom}[1]\n"; # does it need normal bed format?
      }
    }
    close TMP;
    # intersect and print
    `bedtools intersect -a $i\.tmp -b $intersect | awk '{print \$3 - \$2}' | awk '{sum+=\$1} END {print sum}' >> $outfile` ;
     `rm $i\.tmp`;
  } # for
}

sub binary_search {
  my $num = $_[0] ;
  my @indexes = @{$_[1]} ;

  my $first = 0 ;
  my $last = @indexes - 1 ;
  my $middle = int(($last + $first) / 2) ;

  while ($first <= $last) {
    if ($indexes[$middle][0] < $num) {
      $first = $middle + 1 ;
    } 
    elsif ($indexes[$middle][0] == $num) {
      last ;
    }
    else {
      $last = $middle - 1 ;
    }
    $middle = int(($last + $first) / 2) ;
  } 

  return($middle) ;
}

