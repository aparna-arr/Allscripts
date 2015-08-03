#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;
use Cache::FileCache;

control();

# input format:
# chr1 200 300 0
# chr1 300 400 1
# chr1 400 500 2
# ...

sub control {
  my ($beds, $wigs, $cache) = get_input();

  process($beds, $wigs, $cache);
}

sub get_input {
  my ($cache_root, $wigfile, @bedfiles) = @ARGV;
  die "usage: $0 </absolute/path/to/cache/> <wigfile> <bedfiles>" unless @ARGV;

  my $cache = new Cache::FileCache();
  $cache -> set_cache_root($cache_root);

  my ($beds_ref) = split_beds(\@bedfiles, $cache);
  my ($wig_ref) = split_wig($wigfile, $cache);
  
  return ($beds_ref, $wig_ref, $cache);
}

sub split_beds {
  my @beds = @{$_[0]};
  my $cache = $_[1];
  my @bins;

  print "Splitting beds ...\n";

  for (my $i = 0; $i < @beds; $i++) {
    my %bedbin;
    open (BED, "<", $beds[$i]) or die "Could not open $beds[$i]\n";

    my $name = basename($beds[$i], ".bed");

    while (<BED>) {
      my $line = $_;
      chomp $line;
# trusting user on 4col format
      my ($chr, $start, $end, $bin) = split(/\t/, $line);
#      push(@{$bedbin{$chr}{$bin}}, (start => $start, end => $end, score => 0));

      if ($bin == 0) {
        push(@{$bedbin{$chr}}, (start => $start));
      }
      elsif ($bin == 19) { # FIXME hardcoded!
        $bedbin{$chr}{end} = $end;
      }
      
      %{$bedbin{$chr}[@{$bedbin{$chr}} - 1]{bins}[$bin]} = (
        start => $start,
        end => $end,
        score => 0,
        count => 0
      );
  
#      push(@{$bedbin{$chr}}, (start => $start, end => $end, bin => $bin, score => 0));
    }

#    foreach my $chrom (keys %bedbin) {
#      foreach my $bin (keys %{$bedbin{$chrom}}) { # store by index, not bins
#          $bins[$i]{$chrom}{$bin} = "$name\.$chrom\.$bin\.cache";
#          $cache -> set("$bins[$i]{$chrom}{$bin}", \@{$bedbin{$chrom}{$bin}});
#      }
#    }
    close BED;

# store in cache with index possibly
#
    foreach my $chrom (keys %bedbin) {
      $bins[$i]{$chrom} = "$name\.$chrom\.cache";
      $cache -> set("$bins[$i]{$chrom}");
    }
  }

  print "Done splitting beds\n";
  return(\@bins);   
}

sub split_wig {
  my $wig = $_[0];
  my $cache = $_[1];
  my %wigbin;
  my %bins;

  my $name = basename($wig, ".wig");

  print "Splitting wig ...\n";

  open (WIG, "<", $wig) or die "Could not open $wig\n";

  my $chr = "INIT";
  my $span = -1;

  while(<WIG>) {
    my $line = $_;
    next if ($line =~ /\#/);
  
    if ($line =~ /Step/) {
      ($chr, $span) = $line =~ /chrom=(.+)\s+span=(\d+)/;
    }
    elsif ($line =~ /^\d+/) {
      my ($pos, $val) = split(/\t/, $line);
      push(@{$wigbin{$chr}}, (start => $pos, end => $pos+$span, value => $val));
    }
  }

  foreach my $chrom (keys %wigbin) {
    $bins{$chrom} = "$name\.$chrom\.cache";
    $cache -> set("$bins{$chrom}", \@{$wigbin{$chrom}});
  }
  
  close WIG;
  print "Done splitting wig\n\n";
  return(\%bins);
}

sub process {
  my @beds = @{$_[0]};
  my %wig = %{$_[1]};
  my $cache = $_[2];

# instead of going by bin, it might be better to go by bed peak, and place each value/score in corresponding bin after
# as each 1% is quite small
# peak broken up into bins: = = = = = ...
# when we reach the end of bin0, $bed_bin_index++ to get to bin1 of same peak
# if current wig peak still fits, continue
# and $wig_index++ instead of bsearch per bin
# etc until peak is done
# Probably will do about 1/10 the amount of bsearches

  for (my $i = 0; $i < @beds; $i++) {
    foreach my $chr (keys %{$beds[$i]}) {
      my $wig_chr_ref = $cache -> get("$wig{$chr}");
      my @wig_chr = @{$wig_chr_ref};

#      foreach my $bin (keys %{$beds[$i]{$chr}}) {

        my $bed_chr_ref = $cache -> get("$beds[$i]{$chr}");
        my @bed_chr = @{$bed_chr_ref};
        my $start_index = 0;

        for (my $j = 0; $j < @bed_chr; $j++) {
#          my $one_percent = int(($bed_chr[$j]{end} - $bed_chr[$j]{start})/10);
          
          # bsearch here for beginning of 'peak'
          # using $index instead of $start_index in the case of a -1 return
          my $index = binary_search($start_index, $bed_chr[$j]{start}, $bed_chr[$j]{end}, \@wig_chr);

          if ($index == -1) {
            next; # go to next bed peak
            # peak scores are initialized to 0
          }
          for (my $k = 0; $k < @{$bed_chr[$j]{bins}}; $k++) {
  
            if ($wig_chr[$index]{start} > $bed_chr[$j]{bins}[$k]{end}) {
              next; # if the bin ends before the wig signal starts
            }
            
            my $one_percent = int(($bed_chr[$j]{bins}[$k]{end} - $bed_chr[$j]{bins}[$k]{start})/10);
            # make sure one_percent does not == 0
            my @percents;

            for (my $m = 0; $m < 10; $m++) {
              $percents[$m]{val} = 0;
               while ($wig_chr[$index]{start} < $bed_chr[$j]{bins}[$k]{start} + $one_percent * ($m + 1)) {
                if ($wig_chr[$index]{start} < $bed_chr[$j]{bins}[$k]{start} + $one_percent * $m) {
                  # do stuff
                  if ($wig_chr[$index]{end} > $bed_chr[$j]{bins}[$k]{end}) {
                    $percents[$m]{val} += $wig_chr[$index]{value} * ($bed_chr[$j]{bins}[$k]{end} - $bed_chr[$j]{bins}[$k]{start}); # check var name;
                  }
                  else {
                    $percents[$m]{val} += $wig_chr[$index]{value} * ($wig_chr[$index]{end} - $bed_chr[$j]{bins}[$k]{start}); # check var name;
                  }
                } 
                else {
                  # do more stuff fixme just pasted, not changed
                  if ($wig_chr[$index]{end} > $bed_chr[$j]{bins}[$k]{end}) {
                    $percents[$m]{val} += $wig_chr[$index]{value} * ($bed_chr[$j]{bins}[$k]{end} - $wig_chr[$index]{start}); # check var name;
                  }
                  else {
                    $percents[$m]{val} += $wig_chr[$index]{value} * ($wig_chr[$index]{end} - $wig_chr[$index]{start}); # check var name;
                  }
                }
                $index++;
              } # while 
              # need to avg the one percents
              $bed_chr[$j]{bins}[$k]{score} += ($percents[$m]{val}/$one_percent);
              $bed_chr[$j]{bins}[$k]{count}++;
            } # process for 1 percent bins within bin
              $bed_chr[$j]{bins}[$k]{score} /= $bed_chr[$j]{bins}[$k]{count}; # is this right?
          } # for my $k (bins)

        } # for my $j (peaks)

#      } # foreach my bin (bed bins)
    } # foreach my chr (bed chrs)
  } # for my $i (bedfiles)
}

sub binary_search {
  my $min_index = $_[0];
  my $pos = $_[1];
  my $end = $_[2];
  my @array = @{$_[3]};
 
#     =====
#  ----
#
#     =====
#   ---------

#     =====
#      --
#
#     =====   
#        ----

# all of these possibilities can be returned, in the order shown (group of two are equivalent)
# just testing against $pos, not the bed end
# if none of these exist, return -1
}
