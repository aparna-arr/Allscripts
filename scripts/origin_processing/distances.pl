#!/usr/bin/env perl

use warnings ;
use strict ;

my ($origin_file, $dripc_file) = @ARGV ;
die "usage: $0 <origin bedfile> <dripc peakfile>\n" unless @ARGV ;
print "Files MUST be in bed format:\n" ;
print "\tchr#\tstart\tend\n" ;
print "OR ELSE SILENT READ ERROR\n" ;
print "Files MUST BE SORTED going to do a binary search\n" ;

my %origins = %{read_in($origin_file)} ;
my %dripc = %{read_in($dripc_file)} ;

my %results = %{find_distances(\%origins, \%dripc)} ;

print_results(\%results) ;

sub read_in {
  my $file = $_[0] ;
  my %hash ;
  open (IN, "<", $file) or die "Could not open $file\n" ;
  while (<IN>) {
    my $line = $_ ;
    chomp $line ;
    if ($line =~ /track/) {
      next ;
    } 
    my ($chr, $start, $end) = $line =~ /^chr(.+)\t(\d+)\t(\d+).*/ ;
    push (@{ $hash{$chr} }, ($start + $end) / 2) ; #storing only center   
  }
  close IN ;
  return(\%hash) ;
}

sub find_distances {
  my %oris = %{$_[0]} ; 
  my %peaks = %{$_[1]} ;
  my %distances ;
  foreach my $chrom (keys %oris) {
    for (my $i = 0 ; $i < @{$oris{$chrom}} ; $i++) {
      push(@{$distances{$chrom}}, binary_search($oris{$chrom}[$i], \@{$peaks{$chrom}})) ; 
    }
  }
  return (\%distances) ;
}

sub binary_search {
  my $value = $_[0] ;
  my @array = @{$_[1]} ;
  
  my $first = 0 ;
  my $last = @array - 1 ;
  my $middle = int( ($last + $first) / 2 ) ;
  my $min = -1 ;

  while ($first <= $last) {
    if ($array[$middle] < $value) {
      $first = $middle + 1 ;
    }
    elsif ($array[$middle] == $value) {
      $min = 0 ;
      last ;
    }
    else {
      $last = $middle - 1 ;
    }
    $middle = int(($first + $last) / 2) ;
  }
  if ($first > $last ) {
    $min = abs($value - $array[$middle])
  }
  return ($min) ;
}

sub print_results {
  #not sure how to print this out in a way that R can read it
  #figure out box plot data frame first
  #going to print out in seperate files for now
  my %data = %{$_[0]} ;
  my $dir = "distances_outfiles" ; 
  print "Outfiles are by chr and in folder $dir/\n" ;
  `mkdir $dir` ;
  foreach my $chr (keys %data) {
    my $outfile = "$dir/outfile_chr_$chr\_.txt" ;
    open (OUT, ">", $outfile) or die "could not open $outfile\n" ;
    for (my $j = 0 ; $j < @{$data{$chr}} ; $j++) {
      print OUT "$data{$chr}[$j]\n" ;
    }
    close OUT ;
  }
  print "Script done!\n" ;  
}
