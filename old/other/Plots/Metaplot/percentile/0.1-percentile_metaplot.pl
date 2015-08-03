#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;

# Input format
# chrom start end bin
# chr1 10 20 0
# chr2 30 45 0
# chrX 100 200 0
# chr3 300 500 0
# Is this basically like making a metaplot for each bin then putting them together?
# Where is the bin aligned? Does it matter?
# Align at middle
# tmp files by chr. (lowmem). Or bin? Bin would be more even possibly. Exact same number of peaks in each bin. Yes, go by bin. Then can go by chr if needed.
#
# Assume wig is constant span
# Use s50 binary search map
#

control();

sub control {
  my ($bedfiles_ref, $wigfiles_ref) = get_input();
  process($bedfiles_ref, $wigfiles_ref);
}

sub get_input {
  my ($wigfile, @bedfiles) = @ARGV;
  die "usage: $0 <wigfile> <bedfiles>" unless @ARGV;
  
  my ($beds_ref) = split_beds(\@bedfiles);
  my ($wig_ref) = split_wig($wigfile);
  return ($beds_ref, $wig_ref);
}

sub split_beds {
  my @beds = @{$_[0]};
  my %binlines;
  my @binfiles;  

  print "Starting to split beds ...\n";

  for (my $i = 0; $i < @beds; $i++) {
    open (BED, "<", $beds[$i]) or die "Could not open $beds[$i]\n";

    while (<BED>) {
      my $line = $_;
      my ($chr, $bin) = $line =~ /^chr(.+)\t\d+\t\d+\t(\d+)$/;

      $binlines{$bin}{$chr} .= $line; # can deal with unsorted - by - bin
    } 
    
    foreach my $b (keys %binlines) {
      foreach my $chr (keys %{$binlines{$b}}){
        $binfiles[$i]{$b}{$chr} = "bed_$i\_bin_$b\_chr_$chr.tmp";
        open(TMP, ">", $binfiles[$i]{$b}{$chr}) or die "Could not open temp file $binfiles[$i]{$b}{$chr}\n";
        print TMP $binlines{$b}{$chr};
        close TMP;
      }
    }  
    close BED; 
  }
  
  print "Done with splitting beds\n";
  return (\@binfiles);
}

sub split_wig {
  my $wig = $_[0];
  my %wiglines;
  my %wigfiles;
  print "Starting to split wig ...\n";
  
  open (WIG, "<", $wig) or die "Could not open $wig\n";
# wig will be split by chr!

  my $chr = "INIT";

  while(<WIG>) {
    my $line = $_;
# trusting that the user wig file is sane
    next if ($line =~ /\#/);

    if ($line =~ /Step/)  {
      ($chr) = $line =~ /chrom=(.+)/; ## FIXME check!
    } 

    $wiglines{$chr} .= $line;      
  }

  foreach my $chrom (keys %wiglines) {
    $wigfiles{$chrom} = "wig_$chrom.tmp";
    open (TMP, ">", $wigfiles{$chrom});
    print TMP $wiglines{$chrom};
    close TMP;
  }

  close WIG;
  print "Done splitting wig\n";
  return (\%wigfiles);
}

sub process {
  my @bedfiles = %{$_[0]};
  my %wigfiles = %{$_[1]};

  for (my $i = 0; $i < @bedfiles; $i++) {
    foreach my $bin (keys %{$bedfiles[$i]}) {
      foreach my $chr (keys %{$bedfiles[$i]{$bin}}) {
        my @bed;
        my $file = $bedfiles[$i]{$bin}{$chr};
        open (IN, "<", $file) or die "Could not open $file\n";
        
        while(<IN>) {
          my $line = $_;
          chomp $line;  
          my ($chr, $start, $end) = $line =~ /(.+)\t(.+)\t(.+)\t.+/;
          push(@bed, (start => $start, end => $end));
        }
        close IN;

        open (WIG, "<", $wigfiles{$chr}) or die "Could not open wigfile $wigfiles{$chr}\n";
        # should have {chr}[bin] rather than [bin]{chr} as the wigfile will have to be opened ten times every chromosome
        
#        while(<WIG>)
        close WIG;

# this is an incredibly stupid way of doing this, USE A CACHE
  
        for (my $j = 0; $j < @bed; $j++) {
          my $one_percent = int(($bed[$j]{end} - $bed[$j]{start})/10);
          #bsearch here
          for (my $m = 0; $m < 10; $m++) {
            #stuff
          }
        }
      }
    }
  }
}

sub binary_search {
  
}
