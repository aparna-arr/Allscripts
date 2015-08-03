#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;
use Cache::FileCache;

#FIXME takes up ~20GB memory when setting cache, sets cache every time (drip2 wig)
#mem usage is constantly at 20GB. Why?
my ($wig, $cache_name, $window, $shift) = @ARGV;
die "usage: $0 <wig file> <cache_name> <window> <shift>\n" unless @ARGV;

print "\nWIG MUST BE SORTED\n\n";

if ($shift == 0 || $window == 0) {
  die "Shift and Window cannot == 0!\n";
}

my $cache = new Cache::FileCache();
$cache -> set_cache_root("$cache_name");
print "Setting wig into cache $cache_name ...\n";
# make list of chrs and put wig in cache
my %chroms = %{read_wig($wig, $cache)};

# start pos -> start pos + shift - 1 

my %result = %{slide(\%chroms, $shift, $window, $cache)};
print_out(\%result, $shift, $window, $wig);

sub read_wig {
  my $file = $_[0];
  my $cache = $_[1];

  my $filename = basename($file);
  print "debug: read_wig(): filename is $filename\n";
  open (IN, "<", $file) or die "Could not open $wig\n";

  my $chr = "INIT";
  my $curr_chr = "INIT";
  my $span;
  my @wig;
  my %chrs;

  while (<IN>) {
    my $line = $_;
    chomp $line;
    if ($line !~ /^\d/) {
      next if $line !~ /^variableStep/;
      ($chr, $span) = $line =~ /chrom=chr(.+) span=(\d+)/i;

      if ($chr ne $curr_chr && $curr_chr ne "INIT") {
        print "setting chr $curr_chr cache at $filename\.$curr_chr\.cache\n";
        $cache -> set("$filename\.$curr_chr\.cache", \@wig);
        $chrs{$chr} = "$filename\.$curr_chr\.cache";
        @wig = ();
      }
      $curr_chr = $chr;
    }
    else {
      my ($pos, $val) = split(/\t/, $line);
      push(@wig, {start => $pos, value => $val, end => $pos + $span - 1});
    }
  }

  # for last chr  
  print "setting chr $curr_chr cache at $filename\.$curr_chr\.cache\n";
  $cache -> set("$filename\.$curr_chr\.cache", \@wig);
  $chrs{$chr} = "$filename\.$curr_chr\.cache";

  close IN;

  return(\%chrs);
}

sub slide {
  my %chrs = %{$_[0]};
  my $shift = $_[1];
  my $window = $_[2];
  my $cache = $_[3];
  my %values;

#for reference on @wig data structure
#      push(@wig, {start => $pos, value => $val, end => $pos + $span - 1});
  foreach my $chr (keys %chrs) {
    print "\tdebug: slide(): On chr $chr\n";
    my $wig_ref = $cache -> get("$chrs{$chr}");
    my @wig = @{$wig_ref};

    my $min_index = 0;

    for (my $i = $wig[0]{start}; $i <= $wig[@{$wig_ref} - 1]{end} - $window; $i+=$shift) {
#      print "\tdebug: slide(): on position $i\n";
      my $end = $i + $window; # always have $j < $end!
      
      my $value = 0;
      my $start = $i;
      my $j = $min_index;

# assumes wig is SORTED, that wig blocks <<< window size

      if ($wig[$j]{start} < $start) {
        $value += ($wig[$j]{end} - $start) * $wig[$j]{value};
       $j++;
      }

      while($wig[$j]{end} <= $end) {
        $value += ($wig[$j]{end} - $wig[$j]{start}) * $wig[$j]{value};
        $j++;
      }
  
      if ($wig[$j]{start} < $end) {
        $value += ($end - $wig[$j]{start}) * $wig[$j]{value};
        $j++;
      }
      $min_index = $j;

      $values{$chr}{$i} = ($value) / $window;
    }
  }
  return(\%values);
}

sub print_out {
  my %results = %{$_[0]};
  my $shift = $_[1];
  my $window = $_[2];
  my $infile = $_[3];
  my $span = $shift - 1; # FIXME not best value
  my $filename = basename($infile);

  print "Printing out...\n";

# FIXME maybe only print out nonzero?
  # prints in wig format
  open (OUT, ">", "$filename\_slide_outfile_W$window-S$shift\.wig") or die "Could not open outfile\n";

  foreach my $chrom (sort keys %results) {
    print OUT "variableStep chrom=chr$chrom span=$span\n";
    
    foreach my $pos (sort {$a<=>$b} keys %{$results{$chrom}}) {
      print OUT "$pos\t$results{$chrom}{$pos}\n";
    }
  }
  close OUT;
}
