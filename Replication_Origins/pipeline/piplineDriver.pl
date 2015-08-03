#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;

main();

sub main {
  print "
Replication Pipeline

0 Genome-wide simulation BrdU regions
[ <file to be shuffled> <files to be intersected> ]

1 Within-regions origin shuffle
[ <file to be shuffled on> <file to be shuffled> <file to be intersected>]

2 Histone-DRIP peak metaplots

3 Histone-Origin peak metaplots

4 Pairwise early region origins -u -v DRIP, histone signal

5 Pairwise early region DRIP -u -v origins, histone signal

6 Pairwise early subsets origins (data and shuffle) -u -v DRIP, histone signal

7 Pairwise early subsets DRIP (data and shuffle) -u -v origins, histone signal
";

  my (@args) = @ARGV;
  print "usage: $0 <comma seperated numbers> <list of args in order of numbers, arguments for each script surrounded by [ ]>
example: 
$0 0,1,2,3,4 #default args
$0 -1 #all functions, default args" unless @ARGV;

  if ($args[1] == -1) {
    simulation_Genome_BrdU();
    within_Regions_Sim_Origins();
    metaplot_Histone_DRIP();
    metaplot_Histone_Origin();
    pairwise_Origin_DRIP();
    pairwise_DRIP_Origin();
    pairwise_Subsets_Origin_DRIP();
    pairwise_Subsets_DRIP_Origin();
  }
  else {
    my (@nums) = split(/,/, $args[1]);

    for (my $i = 0; $i < @nums; $i++) {
      if ($nums[$i] == 0) {
        simulation_Genome_BrdU();
      }
      elsif ($nums[$i] == 1) {
        within_Regions_Sim_Origins();
      }
      elsif ($nums[$i] == 2) {
        metaplot_Histone_DRIP();
      }
      elsif ($nums[$i] == 3) {
        metaplot_Histone_Origin();
      }
      elsif ($nums[$i] == 4) {
        pairwise_Origin_DRIP();
      }
      elsif ($nums[$i] == 5) {
        pairwise_DRIP_Origin();
      }
      elsif ($nums[$i] == 6) {
        pairwise_Subsets_Origin_DRIP();
      }
      elsif ($nums[$i] == 7) {
        pairwise_Subsets_DRIP_Origin();
      }
    }

  }


}

sub simulation_Genome_BrdU {
#[ <file to be shuffled> <files to be intersected> ]
  my $TO_SHUFFLE = $_[0];
  my @TO_INTERSECT = @{$_[1]};
  my @DEFAULTS = ("/data/aparna/Data/gaps_hg19.bed", "/data/aparna/Data/hg19.genome", ".", "1000000", "$TO_SHUFFLE"); 

  my @outfiles;
  my $outdir = "0_sim_outfiles/";
  `mkdir $outdir`;

  my $cmd = "shuffle_genome.pl " . join(@DEFAULTS, " ") . join(@TO_INTERSECT, " ");

  for ($i = 0; $i < @TO_INTERSECT; $i++) {
    push(@outfiles, $outdir . basename($TO_SHUFFLE) . "_" . basename($TO_INTERSECT[$i]) . ".out ");
    $cmd .= $outfiles[$i];
  } 

  print "0 : cmd is $cmd\n";
  open(CMD, ">", $outdir . "cmd.txt");
  print CMD $cmd;
  close CMD;

  `$cmd`; 

# R script base

  my $R = "library(reshape)\nlibrary(ggplot2)\n\n";

  for (my $j = 0; $j < @outfiles; $j++) {
    $R .= basename($outfiles[$j]) . "<-read.delim(\"$outfiles[$j]\". header=F)\n";
  }
  
  for (my $o = 0; $o < $TO_INTERSECT; $o++) {
    $R .= basename($TO_INTERSECT[$o]) . "_total<-\n";
  } 

  $R .= "\n#for fold, log10\nl<-list(\n";

  for (my $k = 0; $k < @outfiles; $k++) {
    $R .= "\tdata.frame(" . basename($outfiles[$k]) . "=" . basename($outfiles[$k]) . "\$V1[1:1000000]/" . basename($TO_INTERSECT[$k]) . "_total * 100),\n";
  }

  $R .= ")\n\n#for fold, log10()\npoints<-data_frame(\n";
  
  for (my $l = 0; $l < @outfiles; $l++) {
    $R .= "\t" . basename($outfiles[$l]) . "=c(   ),\n";
  }
  
  $R .= ")\n\nmelt(l)\nmelt(points)\n";

  $R .= "\n" . basename($TO_SHUFFLE) . "<-
ggplot(l, aes(x=value)) + 
# for fold, binwidth=0.01
geom_histogram(binwidth=.1, aes(fill=variable)) +
scale_fill_manual(values=gray.colors(" . @outfiles . "start=" . (0.4 - @outfiles * 0.1) . ", end=" . (0.4 + @outfiles * 0.1) . ")) +
facet_grid(variable ~ .) +
geom_vline(data=points, aes(xintercept=value), linetype=\"dashed\", size=1, color=\"red\") +
# for fold, Shuffle_1 / Shuffle_2 Fold Increase
ggtitle(\"" . basename($TO_SHUFFLE) . " Percent Overlap\") + 
# for fold, log10(shuffle_1 / shuffle_2)
xlab(\"overlap / sample_total_bp * 100\")
";

  print "$outdir" . "0_Rscript.R";
  open (OUT, ">", $outdir . "0_Rscript.R");
  print OUT $R;
  close OUT;
}

sub within_Regions_Sim_Origins {
#[ <file to be shuffled on> <file to be shuffled> <file to be intersected>]
  my $SHUFFLE_ON = $_[0];
  my $TO_SHUFFLE = $_[1];
  my $TO_INTERSECT = $_[2];

  my $outdir = "1_within_region_sim_outfiles/";
  `mkdir $outdir`;
  my $outfile = $outdir . basename($SHUFFLE_ON) . "_" . basename($TO_SHUFFLE) . "_" . basename($TO_INTERSECT) . ".out";

  my $cmd = "shuffle_within_regions.pl $SHUFFLE_ON $TO_SHUFFLE 1000 $TO_INTERSECT $outfile";

  # no R script
}

sub metaplot_Histone_DRIP {

}

sub metaplot_Histone_Origin {

}

sub pairwise_Origin_DRIP {
  my $ORIGINS = $_[0];
  my $DRIP = $_[1];
  my @WIGS = @{$_[2]}; 

  my $outdir = "4_pairwise_origin_drip/";

  `mkdir $outdir; mkdir $outdir/peaks; mkdir $outdir/maps`; # will the double slash work?

  `bedtools intersect -u -a $ORIGINS -b $DRIP > $outdir/peaks/$ORIGINS\_$DRIP\_u.bed`;
  `bedtools intersect -v -a $ORIGINS -b $DRIP > $outdir/peaks/$ORIGINS\_$DRIP\_v.bed`;

  for (my $i = 0; $i < @WIGS ; $i++) {
    `cd $outdir/maps/ ; perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -w $WIGS[$i] -r /data/aparna/cache/ $outdir/peaks/$ORIGINS\_$DRIP\_u.bed $outdir/peaks/$ORIGINS\_$DRIP\_v.bed`;
    # where does this script place outfiles? in the path or . ?
    
  } 
}

sub pairwise_DRIP_Origin {

}

sub pairwise_Subsets_Origin_DRIP {

}

sub pairwise_Subsets_DRIP_Origin {

}

# need to add the corr heatmap: how many arguments to add to that function? But the R script will be self-contained.
# pie chart?
# s50 diagram
# compare specific vs constitutive
# wig of bed efficiency from picard
