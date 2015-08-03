#!/usr/bin/env perl
use warnings;
use strict;

my ($bed, $wig, $subset_dir) = @ARGV;
die "usage: $0 <bed file> <wig file> <genomic subsets dir>
bed format:
chr start end name  val strand
wigfile name can have MAX one \"_\"
" unless @ARGV == 3;

my @subsets = <$subset_dir/*>;

my ($bedname) = $bed =~ /\/*([^\/]+)\..+$/; 
my ($wigname) = $wig =~ /\/*([^\/]+)\..+$/; 

#die "[$bedname] [$wigname]\n";
print "debug: reading bed\n";
my %bed = %{readBed($bed)};
print "debug: done reading bed\n";
my $region;
for (my $i = 0; $i < @subsets; $i++) {
  ($region) = $subsets[$i] =~ /\/genomic_(.+)\.bed/;

#  print "debug: subset $region\n";
#  print "debug: beginning intersect\n";
  %bed = %{intersect($subsets[$i], \%bed)};
#  print "debug: done with intersect\n";
  print "Starting map\n";

  system("perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -r /data/aparna/cache/ -p -w $wig $bedname\_$region.bed");

  print "Done with map, starting calculate heatmap\n";

  system("perl -I /usr/local/bin/Perl /usr/local/bin/Perl/calculate_heatmap.pl $wigname\_$bedname\_$region.txt");
  system("cp $wigname\_$bedname\_$region.tsv $wigname\_drip_$region\_orig.tsv"); 
  system("mv $wigname\_$bedname\_$region.tsv $wigname\_drip_$region\_shuf.tsv"); 

  print "Done with calculate heatmap\n";

  system("perl -I /usr/local/bin/Perl Graph.pl -r /data/shared/NT2.rpkm -a $wigname\_drip_$region\_orig.tsv -b $wigname\_drip_$region\_shuf.tsv");
}

sub readBed {
  $bed = $_[0];
  open (IN, "<", $bed) or die "Could not read bed $bed\n";

  my %bed;

  while (<IN>) {
    my $line = $_;
    chomp $line;
  
    if ($line !~ /^chr/) {
      next;
    }

    my ($chr, $start, $end, $name, $val, $strand, $trash) = split(/\t/, $line);
   
    if ($start !~ /^\d+$/ || $end !~ /^\d+$/) {
      next;
    }
    push(@{$bed{$chr}}, {start => $start, end => $end, strand => $strand}); 
  }

  close IN;
  return(\%bed);
}

sub intersect {
  my $subset_file = $_[0];
  my %bed = %{$_[1]};

  my %subset;

  open (IN, "<", $subset_file) or die "could not open $subset_file\n";

  while (<IN>) {
    my $line = $_;
    chomp $line; 

    my ($chr, $start, $end, $name, $value, $strand, $trash) = split(/\t/, $line);
    push(@{$subset{$chr}}, {start => $start, end => $end, strand => $strand, gene => $name}); 
  } 
  close IN;
 
  print "$bedname\_$region.bed\n"; 
  open (OUT, ">", "$bedname\_$region.bed") or die "Could not open outfile\n";

  foreach my $chrom (keys %subset) {
    if (!exists($bed{$chrom})) {
      next;
    }
    ## binary search on bed ##
    ## return unused peaks ##
    ## print used peaks ##
    
    for (my $i = 0; $i < @{$subset{$chrom}}; $i++) {
      my $sub_start = $subset{$chrom}[$i]{start};
      my $gene = $subset{$chrom}[$i]{gene};
      my $index = bsearch($sub_start, \@{$bed{$chrom}});

#      print "$sub_start\n";
      if (!exists($bed{$chrom}[$i]{end}) || !exists($bed{$chrom}[$i]{start})) {
#        print "!exists $bed{$chrom}[$i]{end}\n";
        last;
      }
      if ($index >= @{$bed{$chrom}}) {
        last;
      }
      if ($bed{$chrom}[$i]{end} < $sub_start) {
        next;
      }
#      print "i is $i before [$chrom]\t[$bed{$chrom}[$index]{start}]\t[$bed{$chrom}[$index]{end}]\t[$gene]\t.\t[$bed{$chrom}[$index]{strand}]\n";
      # guaranteed here, bed index is within subset region coords
      # =====
      #  -----
      #
      #  X
      #       ====
      # ----
      #
      # X
      # ===
      #      ----
      # Therefore here, we know that bed and subset must intersect here

      # slice out of bed array and print
#      my (%element) = %{splice(@{$bed{$chrom}}, $index, 1)};
      my %element = (
        start => $bed{$chrom}[$index]{start},
        end => $bed{$chrom}[$index]{end},
        strand => $bed{$chrom}[$index]{strand}
      ); 
      if (!exists($element{start}) || $element{start} !~ /^\d+$/ || $element{end} !~ /^\d+$/) {
        next;
      } 

      print OUT "$chrom\t$element{start}\t$element{end}\t$gene\t.\t$element{strand}\n";
#      print "i is $i after [$chrom]\t[$element{start}]\t[$element{end}]\t[$gene]\t.\t[$element{strand}]\n";
    }
  }
  
  close OUT;
  return (\%bed);
}

sub bsearch {
  my $query = $_[0];
  my @ar = @{$_[1]};
  my $first = 0;
  my $last = @ar - 1;
  my $mid = int(($first + $last)/2);

  while ($first <= $last) {
    if (!exists($ar[$mid]{start})) {
      $mid++;
      last;
    }

    if ($ar[$mid]{start} < $query) {
      $first = $mid + 1;
    }
    elsif ($ar[$mid]{start} == $query) {
      last;
    }
    else {
      $last = $mid - 1;
    }
    $mid = int(($first + $last)/2);
  }
  
  if (exists($ar[$mid]{start}) && $ar[$mid]{end} < $query) {
    $mid++;
  }
  return($mid); # guaranteed that bed index >= subset start
}
