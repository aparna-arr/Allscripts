#!/usr/bin/env perl
use warnings;
use strict;

# This script calculates G4 density over a set of bed coordinates
# given a fasta file and a bed peak file
# Ignores strands 
# (is for replication analysis, which is strand-independent)
# bedgraph format
#
# Input: Bed file of peaks, fasta of bed data
# Output: Wig density of G4 motifs
#
# Window size: 100, shift: 20 by default

my ($bed, $fasta, $outfile) = @ARGV;
die "usage: $0 <bed> <fasta> <outfile.wig>\n" unless @ARGV;

my $tmp = "tmp.fa";

`fastaFromBed -fi $fasta -bed $bed -fo $tmp`;

open (TMP, "<", $tmp) or die "Could not open $tmp:$!\n";

my $chr = "INIT";
my ($start, $end) = 0;

my %seq;

while(<TMP>)
{
  my $line = $_;
  chomp $line;
  
  if ($line =~ /^>/)
  {
    # header line
    ($chr, $start, $end) = $line =~ /^>(.+):(\d+)-(\d+)$/;
  }
  else
  {
    # assuming NON-BROKEN fasta line
    push(@{$seq{$chr}}, {start => $start, end => $end, seq => $line});
  }
}

open (OUT, ">", $outfile) or die "Could not open $outfile:$!\n";

foreach my $chrom (keys %seq) 
{
  for (my $i = 0; $i < @{$seq{$chrom}}; $i++)
  {
    # analyze G4 sequence
    # run sliding window here
    my $curr_pos = $seq{$chrom}[$i]{start};
    my $strlen = length($seq{$chrom}[$i]{seq});

    while(1)
    {
      if ($strlen - ($curr_pos+100) < 0)
      {
        last;
      }

      my ($subseq) = substr($seq{$chrom}[$i]{seq}, $curr_pos, 100); 

      my ($density) = analyze($subseq);

#      push(@{$seq{$chrom}[$i]{density}}, $density);
      print OUT "$chr\t$curr_pos\t" . $curr_pos . "\t$density\n";
  
      $curr_pos += 20;
    }
  }
}

close OUT;

close TMP;
`rm $tmp`;

sub analyze 
{
  my $seq = $_[0];

  # naive G4 regex (greedy)

  if ($seq =~ /(GGGG*[ACGT]*){3}GGGG*/)
  {
    return 1;
  }

  return 0;
}



