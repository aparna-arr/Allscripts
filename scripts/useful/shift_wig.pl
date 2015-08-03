#!/usr/bin/env perl
use warnings;
use strict;

my $warning = "
Warnings:
This script linearly shifts values in a wig file by multiplying each value by the factor input
Lowmem : split by chr. <chr>.wig.tmp
Makes dir tmp/ shifts all *.tmp into tmp/
FIXME: Bug in readin()
Outfile: shift.out

";

my ($wig, $factor) = @ARGV;
die "usage: $0 <wig file> <factor to MULTIPLY values by>\n$warning" unless @ARGV == 2;

print $warning;

my $filename = $wig =~ /\/(.+)$/;
#open(OUT, ">", $filename . ".shift");
open(OUT, ">", "shift.out");

print "\nReading in...\n";
my %chrs = %{split_wig($wig)};
print "\nDone reading in. Starting shift for ...\n";
foreach my $chr (sort keys %chrs) {
  print "$chr\n";
  my @vals = @{readin($chrs{$chr})};
  my @shifted = @{shift_vals(\@vals, $factor)};
  print_out(\@shifted);
}

close OUT;

`mkdir tmp`;
`mv *.tmp tmp`;

sub split_wig {
  my $wig = $_[0];
  my %small_wigs;
  
  open (IN, "<", $wig) or die "Could not open $wig\n";

  my $span = -1;
  my $prev_chr = "INIT";

  while(<IN>) {
    my $line = $_;
    if ($line =~ /^\#/ || $line =~ /^track/) {
      next;
    }

    if ($line =~ /^variableStep/) {
      my ($chr) = $line =~ /^variableStep chrom=(.+) span=.+/;

        if ($prev_chr ne "INIT" && $prev_chr ne $chr) {
          close TMP;
        }
        if (!exists($small_wigs{$chr})) {
          print "$chr\n";
          $small_wigs{$chr} = "$chr.wig.tmp";
          open (TMP, ">", "$chr.wig.tmp") or die "could not open tempfile\n";
        }
        print TMP $line;
        $prev_chr = $chr;  
    }
    if ($line =~ /^\d+/) {
      print TMP $line;
    }
  }
  close IN;

  return(\%small_wigs);
}

sub readin {
  my $file = $_[0];
  my @values;

  open (IN, "<", $file) or die "Could not open $file\n";
    
  my $span;
  my $header;
  while(<IN>) {
    my $line = $_;  
    chomp $line;
    
    if ($line =~ /variableStep/) {
      $header = $line;
      ($span) = $line =~ /variableStep chrom=.+ span=(.+)/;
    }
    elsif($line =~ /\d+/) {
      my ($pos, $val) = split(/\s+/, $line);
      if (!defined($val)) {
        print "$file !defined val. line = [$line] Ignoring line, copying file to PROBLEM\n";
        `cp $file PROBLEM`;
        next;
      }

      push(@values, {header => $header, pos => $pos, val => $val});
    }
  }
  close IN;
  return(\@values);
}

sub shift_vals {
  my @values = @{$_[0]};
  my $multiply = $_[1];
    
  for (my $i = 0; $i < @values; $i++) {
    if (!defined($values[$i]{val})) {
      print "!defined val = [$values[$i]{val}] pos = [$values[$i]{pos}]\n";
    }
    $values[$i]{val}*=$multiply;
  }
  return(\@values);
}

sub print_out {
  my @outvals = @{$_[0]};

  for (my $i = 0; $i < @outvals; $i++) {
    if ($i == 0 || $outvals[$i]{header} ne $outvals[$i-1]{header}) {
      print OUT "$outvals[$i]{header}\n";
    }
    print OUT "$outvals[$i]{pos}\t$outvals[$i]{val}\n";
  }
}

