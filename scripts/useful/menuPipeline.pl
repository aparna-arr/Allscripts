#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;
use Cache::FileCache;

# Need to add
#   R scripts
#   Metaplot
#   Better usage
#   More files in %hash

my %hash = (

  K562_DRIPc => "/data/aparna/Data/K562/K562_DRIPc_all_peaks.bed",
  K562_DRIP => "/data/aparna/Data/K562/K562_DRIP_peaks.bed",
  K562_DRIPc_wig => "/data/aparna/Data/K562/LS42B_all.wig",
  K562_DRIP_wig => "/data/aparna/Data/K562/LS42C_treat_afterfiting_all.wig",
  K562_oris => "/data/aparna/Replication_Origins/Picard/k562_oris/K562_oris.bed",
  K562_BrdU_early => "/data/aparna/Replication_Origins/BrdU/origin_files/ENCODE/K562_early_origins_all.txt",
  K562_BrdU_late => "/data/aparna/Replication_Origins/BrdU/origin_files/ENCODE/K562_late_origins_all.txt",
  K562_BrdU_G1 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/g1_all.txt.clean",   
  K562_BrdU_S1 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/s1_all.txt.clean",   
  K562_BrdU_S2 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/s2_all.txt.clean",   
  K562_BrdU_S3 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/s3_all.txt.clean",   
  K562_BrdU_S4 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/s4_all.txt.clean",   
  K562_BrdU_G2 => "/data/aparna/Replication_Origins/BrdU/origin_files/time_specific/K562_ENCODE/g2_all.txt.clean",   

  K562_early_oris => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_early_oris.bed",

  K562_H4K20me1_wig => "/data/aparna/Data/K562/histones/K562_H4K20me1.wig",
  K562_H3K79me2_wig => "/data/aparna/Data/K562/histones/K562_H3K79me2.wig",
  K562_H3K4me1_wig => "/data/aparna/Data/K562/histones/K562_H3K4me1.wig",
  K562_H3K9me3_wig => "/data/aparna/Data/K562/histones/K562_H3K9me3.wig",

  K562_picard_u_drip => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_oris_u_K562_DRIP.bed",
  K562_picard_v_drip => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_oris_v_K562_DRIP.bed",
  K562_drip_u_picard => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_DRIP_u_K562_oris.bed",
  K562_drip_v_picard => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_DRIP_v_K562_oris.bed",
  
  K562_picard_u_dripc => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_oris_u_K562_DRIPc.bed",
  K562_picard_v_dripc => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_oris_v_K562_DRIPc.bed",
  K562_dripc_u_picard => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_DRIPc_u_K562_oris.bed",
  K562_dripc_v_picard => "/data/aparna/Replication_Origins/Picard/k562_oris/intersects/K562_DRIPc_v_K562_oris.bed",

  NT2_DRIP => "/data/wearn/NT2_dripc/Peaks/NT2_DRIP_intersect_peaks.bed",
  NT2_DRIPc => "/data/wearn/NT2_dripc/Peaks/NT2_DRIPc_merged_rep12_intersect_peaks.bed",
  cpg => "/data/aparna/Data/cpg_clean.bed",
  BrdU_3cell_early => "/data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_early_origins.txt",
  BrdU_3cell_late => "/data/aparna/Replication_Origins/BrdU/origin_files/common_origins/K562_HeLa_IMR90/3cell_common_late_origins.txt",
  picard => "/data/aparna/Replication_Origins/Picard/files/intersect_cons_oris.bed",
  genes => "/data/aparna/Data/hg19_gene_merged.bed",
  genes_clean => "/data/aparna/Data/clean_genelist_hg19.bed",
  h4k20me1 => "/data/aparna/Replication_Origins/BrdU/correlations/h4K20me1/dataset/H4K20me1.wig",
  drip_wig => "/data/aparna/Data/NT2_drip_both_treat_afterfiting_all.wig",
  dripc_wig => "/data/wearn/NT2_dripc/Combined_reps/NT2_dripc_MACS_wiggle/treat/NT2_dripc_treat_afterfiting_all.wig",
  orc1_wig => "/data/aparna/Replication_Origins/Picard/mapping/orc1/drip/ORC1_ChIPseq_HeLa_Gradient.bedGraph.wig",
  h3k79me2 => "/data/aparna/Data/H1ESC_H3K79me2.wig",
  h3k4me1 => "/data/mitochi/Work/Project/DRIPc/4_Chromatin/Chromatin/signal/promoter_Set/H3K4me1.wig",
  h3k9me3 => "/data/mitochi/Work/Project/DRIPc/4_Chromatin/Chromatin/signal/promoter_Set/H3K9me3.wig",
  testwig => "/data/aparna/Data/testwig_drip.wig",
  testbed => "/data/aparna/Data/testbed_drip.bed",
  drip_prom => "drip_promoter.bed",
  picard_early => "/data/aparna/Replication_Origins/Picard/files/peaks/picard_intersect_I_3cell_early.bed",
  picard_u_drip => "/data/aparna/Replication_Origins/Picard/files/peaks/picard_intersect_-u_DRIP_intersect.bed",
  picard_v_drip => "/data/aparna/Replication_Origins/Picard/files/peaks/picard_intersect_-v_DRIP_intersect.bed",
  drip_u_picard => "/data/aparna/Replication_Origins/Picard/files/peaks/drip_intersect_-u_picard_intersect.bed",
  drip_v_picard => "/data/aparna/Replication_Origins/Picard/files/peaks/drip_intersect_-v_picard_intersect.bed",
  picard_u_dripc => "/data/aparna/Replication_Origins/Picard/files/peaks/picard_intersect_-u_dripc_intersect.bed",
  picard_v_dripc => "/data/aparna/Replication_Origins/Picard/files/peaks/picard_intersect_-v_dripc_intersect.bed",
  dripc_u_picard => "/data/aparna/Replication_Origins/Picard/files/peaks/dripc_intersect_-u_picard_intersect.bed",
  dripc_u_picard => "/data/aparna/Replication_Origins/Picard/files/peaks/dripc_intersect_-u_picard_intersect.bed",
  drip_dripc_intersect => "/data/aparna/Data/peak_intersects/drip_intersect_Intersect_dripc_intersect.bed",
  drip_dripc_merge => "/data/aparna/Data/peak_intersects/drip_intersect_Merge_dripc_intersect.bed",
  drip_u_genes => "/data/aparna/Data/peak_intersects/drip_intersect_-u_merged_genes.bed",
  drip_v_genes => "/data/aparna/Data/peak_intersects/drip_intersect_-v_merged_genes.bed",
  dripc_u_genes => "/data/aparna/Data/peak_intersects/dripc_intersect_-u_genes.bed", 
  dripc_v_genes => "/data/aparna/Data/peak_intersects/dripc_intersect_-v_genes.bed"
);

main();

sub main {
  
  print "
Replication Pipeline
-1 Run All

0 Genome-Wide simulation

1 Within-regions shuffle

2 Pairwise early region A -u -v B, mapped to C signal

3 Pairwise early subsets A (data and shuffle) -u -v B, C signal

4 Peak Metaplots

5 Phase breakdown simulation

6 Correlation heatmaps

7 Print %hash options
";

  print "Enter comma seperated selections:\n> ";
  my $args = <>;
  chomp $args;

  my (@argAr) = split(/,/, $args);

  for (my $i = 0; $i < @argAr; $i++) {

    if ($argAr[$i] == -1) {
      genome_shuffle();
      within_regions_shuffle();
      pairwise();
      pairwise_subsets();
      metaplot();
      corr_heatmap();    

# MAnorm
# correlation heatmaps
# PCA/dual heatmap matrix
    }
    elsif ($argAr[$i] == 0) {
      genome_shuffle();
    }
    elsif ($argAr[$i] == 1) {
      within_regions_shuffle();
    }
    elsif ($argAr[$i] == 2) {
      pairwise();
    }
    elsif ($argAr[$i] == 3) {
      pairwise_subsets();
    }
    elsif ($argAr[$i] == 4) {
      metaplot();
    }
    elsif ($argAr[$i] == 5) {
      phase_breakdown();
    }
    elsif ($argAr[$i] == 6) {
      corr_heatmap();    
    }
    elsif ($argAr[$i] == 7) {
      foreach my $file (keys %hash) {
        print "$file\n";
      }
    }
  } # for() 
} # main()

sub genome_shuffle {
  print "File to shuffle\n> ";
  my $shuffle = <>;
  chomp $shuffle;
  print "File(s) to intersect (space-separated)\n> ";
  my $intersect = <>;
  chomp $intersect;
  print "tmp dir\n> ";
  my $tmpdir = <>;  
  chomp $tmpdir;

  my $outdir = "0/";

  my $cmd = "shuffle_genome.pl /data/aparna/Data/gaps_hg19.bed /data/aparna/Data/hg19.genome $tmpdir 1000000 $hash{$shuffle} ";

  my (@intfiles) = split(" ", $intersect);

  for (my $j = 0; $j < @intfiles; $j++) {
    $cmd .= $hash{$intfiles[$j]} . " " ;
  }

  for (my $i = 0; $i < @intfiles; $i++) {
    $cmd .= $outdir . basename($hash{$shuffle}) . "_" . basename($hash{$intfiles[$i]}) . ".out ";
  }

  print "0: cmd is $cmd\n\n";
  
  print "Printing outfiles to dir $outdir\n";

  `mkdir 0/`;
  `$cmd`;
}

sub within_regions_shuffle {
  print "File to shuffle\n> ";
  my $shuffle = <>;
  chomp $shuffle;
  print "File to be shuffled on\n> ";
  my $shuffle_on = <>;
  chomp $shuffle_on;
  print "File to be intersected\n> ";
  my $intersect = <>;
  chomp $intersect;

  my $outdir = "1/";

  my $cmd = "shuffle_within_regions.pl $hash{$shuffle_on} $hash{$shuffle} 1500 $hash{$intersect} " . $outdir . basename($hash{$shuffle_on}) . "_" . basename($hash{$shuffle}) . "_" . basename($hash{$intersect}) . ".out";

  print "1: cmd is $cmd\n\n";

  print "Printing outfiles to dir $outdir\n";

  `mkdir 1/`;
  `$cmd`;
}

sub pairwise {
#4 Pairwise early region origins -u -v DRIP, histone signal

  print "[A] -u -v B\n> ";
  my $a = <>;
  chomp $a;
  chomp $a;
  print "A -u -v [B]\n> ";
  my $b = <>;
  chomp $b;
  print "File to map to\n> ";
  my $map = <>;
  chomp $map;

  my $outdir = "2/";

  my $intcmd = "bedtools intersect -u -a $hash{$a} -b $hash{$b} > " . $outdir . basename($hash{$a}, ".bed") . "_" . basename($hash{$b}, ".bed") . "_u.out; bedtools intersect -v -a $hash{$a} -b $hash{$b} > " . $outdir . basename($hash{$a}, ".bed") . "_" . basename($hash{$b}, ".bed") . "_v.out";

  print "2: intersect cmd is $intcmd\n\n";
  print "Printing outfiles to dir $outdir\n";

  `mkdir 2/`;
  `$intcmd`;

  my $mapcmd = "cd $outdir; perl -I /usr/local/bin/Perl/ /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -w $hash{$map} -r /data/aparna/cache/ " . basename($hash{$a}, ".bed") . "_" . basename($hash{$b}, ".bed") . "_u.out " . basename($hash{$a}, ".bed") . "_" . basename($hash{$b}, ".bed") . "_v.out";

  print "2: map cmd is $mapcmd\n\n";
  print "Printing outfiles to dir $outdir\n";

  `$mapcmd`;

  # Now need R script
}

sub pairwise_subsets {
# depending on Rdriver_subsets.pl script from /data/aparna/Data/shuffle_picard_early/Final/testscript

  print "Subsets out dir\n> ";
  my $indir = <>; 
  chomp $indir;
  print "File to map\n> ";
  my $map = <>;
  chomp $map;
  print "File to intersect\n> ";
  my $intersect = <>;
  chomp $intersect;
  
  my $outdir = "3/";
  # must put this script in scripts/ also check dir of outfile printing
  my $cmd = "cd $outdir; Rdriver_subsets.pl $indir $hash{$map} $hash{$intersect} /data/aparna/cache/";

  print "3: cmd is $cmd\n\n";
  print "Printing outfiles to dir $outdir\n";

  `$cmd`;

  print "Modification of R script is required!\n";
}

sub metaplot {
# peak center
# percentile? -> probably
#   Also a nonpercentile fixed-bp option in case percentile gets messy / low res
# expression breakdown? A subsets option? -> seperate metaplots for subsets -> user input. Percentile would not make much sense here
# nonpercentile = avg length of peak/x-axis (median?) so it is not a totally arbitrary constant
#   or user input

  my $constant;

  print "File to map\n> ";
  my $map = <>;
  chomp $map;
  print "Cache set? (1/0)\n> ";
  my $cache_set = <>;
  chomp $cache_set;
  print "Space-seperated list of bed files\n> ";
  my $bed_str = <>;
  chomp $bed_str;
  my (@beds) = split(/\s/, $bed_str);
  print "Percentile? (1/0)\n> ";
  my $perc_opt = <>;
  chomp $perc_opt;
  print "Space-seperated names in order of bed files\n> ";
  my $name_str = <>; 
  chomp $name_str; 
  my (@names) = split(/\s/, $name_str);
  print "Enter outfile basename\n> ";
  my $outfile = <>;
  chomp $outfile;
  my $processed;

  my $avg_opt = 0;
#  print "debug: perc_opt is [$perc_opt]\n";

  if (!$perc_opt) {
    print "Plot will be centered at peak center\n";
    print "10bp avg?(1/0)\n> ";
    $avg_opt = <>;
    chomp $avg_opt;
    print "Enter total peak length to be plotted\n> ";
    my $UI_len = <>;  
    chomp $UI_len; 
    
    print "Preprocessing files";
    $processed = preprocess(\@beds, 1, $UI_len); # centered
  } 
  else {
    print "Enter constant\n> ";
    $constant = <>;
    chomp $constant;

    for (my $i = 0; $i < @beds; $i++) {
      print "Preprocessing file $hash{$beds[$i]}\n";
      $processed = preprocess(\@beds, 0); 
    }
  }
 
  my $name = basename($hash{$map}, ".wig");  
  
  if (!$cache_set) {
#    readin_wig($hash{$map}, $cache, $name);
    readin_wig($hash{$map});
  }

  print "Done preprocessing\n"; 
  
  my @lines;
  $lines[0] = "percent\t" . join("\t", @names) . "\n0\t";

  for (my $n = 1; $n < $constant; $n++) {
    $lines[$n] = "$n\t";
  }

  my $cache = new Cache::FileCache();
  my $cache_root = '/data/aparna/cache/';
  $cache -> set_cache_root($cache_root);

  print "Mapping\n";
  my ($percent_ref) = map_values($processed, $name, $perc_opt, $avg_opt, $cache, $constant);
  @lines = @{print_results($percent_ref, \@lines, scalar(@beds))}; 

  r_graph(\@lines, \@names, $outfile);
  print "Done mapping\n";

}

sub preprocess {
  # expect a format of 
  # chr1  10  20
  my @input = @{$_[0]};
  my $center_opt = $_[1];
  my $len;
  my %outdata;

  if ($center_opt) {
    $len = $_[2];    
  }

  for (my $i = 0; $i < @input; $i++) {
    open (IN, "<", $hash{$input[$i]}) or die "Could not open input bed $hash{$input[$i]}\n";

  while(<IN>) {
    my $line = $_;
    chomp $line;
  
    my ($chr, $start, $end) = $line =~ /^(...\S+)\s+(\d+)\s+(\d+)\s*.*$/;

    if ($center_opt) {
      push(@{$outdata{$chr}[$i]}, {start => ((($start - $end / 2) + $start) - ($len / 2)), end => ((($start - $end / 2) + $start) + ($len / 2))} );
    }
    else {

      if ($start - .25*$start < 0) {
        next;
      }
#      print "chr is $chr\n";
      push(@{$outdata{$chr}[$i]}, {start => $start - .25*$start, end => $end + .25*$end});
    }
  }

  close IN;
  }
  return (\%outdata);  
}

sub readin_wig {
  my $file = $_[0];
  
  `./store_big_wig_in_cache.pl $file`;
  print "Done reading in\n";
}

sub map_values {
  my %chr = %{$_[0]};
  my $name = $_[1];
  my $perc_opt = $_[2];
  my $avg_opt = $_[3];
  my $cache = $_[4];
  my $constant = $_[5];
  # Map file will be ordered
  # Probably a fixed span but cannot assume

  # Optimize!

  my @percents;

  foreach my $bedchr (keys %chr) {

    my $ref = $cache -> get("$name\.$bedchr\.cache");
#    print "$name\.$bedchr\.cache\n";  
    if (!$ref) {
      next;
    }    

    my @wig = @{$ref};
	  
    print "\tRunning for chr $bedchr ...\n";
    
    for (my $bed = 0; $bed < @{$chr{$bedchr}}; $bed++) {
	    my $min_index = 0; # ASSUMES SORTED WIG

	    for (my $i = 0; $i < @{$chr{$bedchr}[$bed]}; $i++) {
#	      print "\tFor peak $i of " . @{$chr{$bedchr}[$bed]} . "\n";
	
	      if ($chr{$bedchr}[$bed][$i]{end} > $wig[@wig - 1]{end}) {
	        last;
	      }
	
	      # Bsearch start
	      my $min = $min_index;
	      my $val = $chr{$bedchr}[$bed][$i]{start};
	      my $max = @wig - 1;
	      my $index = int(($max + $min) / 2);
	
	      while ($min < $max) {
	        $index = int(($max + $min) / 2);
	
	        if ($wig[$index]{start} < $val) {
	          $min = $index + 1;
	        }   
	        elsif ($wig[$index]{start} == $val) {
	          last;
	        }
	        else {
	          $max = $index - 1;
	        } 
	      } # while()
	
	      if ($wig[$index]{start} > $val) {
	        $index--;
	      }
	      # Bsearch end
	
	      my $bedstart = $chr{$bedchr}[$bed][$i]{start};
	      my $bedend = $chr{$bedchr}[$bed][$i]{end};
	
	      ### Percentile
	      my $len = $bedend - $bedstart;
	      my $oneperc = int($len/$constant); # peaks must be 150bp at MINIMUM
	
	      while ($index < @wig && $wig[$index]{start} < $bedend) {
#	        print "\twhile wigstart - wigend is " . ($wig[$index]{end} - $wig[$index]{start}) ." bedstart - bedend is " . ($bedend - $bedstart) . " oneperc is $oneperc\n";
	        my $pt = int( ( $wig[$index]{start} - $bedstart ) / $len * $constant);
	
	        if ($pt < 0) {
	          $pt = 0;
	        }
	
	        my $end = int(($wig[$index]{end} - $bedstart) / $len * $constant) + 1;
        
          if ($end > $constant) {
            $end = $constant;
          }
 
#          print "\t\tdiff is " . ($end - $pt) . " pt is $pt, end is $end\n";	
#	        print "\t\tbefore for\n";
	        for(my $m = $pt; $m < $end; $m++) {
	          if ($bedstart + $oneperc * $m > $wig[$index]{end}) {
	            last;
	          }
	            $percents[$bed][$m]{val} += ($wig[$index]{value} * $oneperc); 
	            $percents[$bed][$m]{count} += $oneperc;
	        }
#	        print "\t\tafter for\n";
	        $index++;
          #die;
	      }
	      ### Percentile
	
	### BP
	#      while ($wig{$bedchr}[$index]{start} < $bedend) {
	#        my $start = -1;
	#        my $end = -1;
	#
	#        if ($wig{$bedchr}[$index]{end} > $bedend) {
	#          $end = $bedend - $bedstart;
	#        } # if
	#        else {
	#          $end = $wig{$bedchr}[$index]{end} - $bedstart;
	#
	#          if ($end < 0) {
	#            $index++;
	#            next;
	#          } # if
	#
	#        } # else
	#
	#        if ($wig{$bedchr}[$index]{start} < $bedstart) {
	#          $start = 0;
	#        } # if
	#        else {
	#          $start = $wig{$bedchr}[$index]{start} - $bedstart;
	#        } # else
	#
	#        for (my $j = $start; $j < $end; $j++) {
	#          $out{$bedchr}[$j]{val} += $wig{$bedchr}[$index]{value};
	#          $out{$bedchr}[$j]{count}++; # FIXME check if this is init to 0! -> done
	#        }
	#
	#        $index++;
	#      } # while
	### BP
	      # re-set min index
	      $min_index = $index;
	    } #for i (peaks)
    } #for bed
  } #foreach

#  return(\%out, \%percents);
  return (\@percents);
}

sub print_results {
  my @results = @{$_[0]};
  my @lines = @{$_[1]};
  my $beds = $_[2];

  for (my $i = 0; $i < @lines; $i++) {
  for (my $n = 0; $n < $beds; $n++) {
    if ($results[$n][$i]{count} == 0) {
      $lines[$i] .= "NA\t";
    }
    else {
      $lines[$i] .= $results[$n][$i]{val} / $results[$n][$i]{count} . "\t";
    }
  }
  $lines[$i] .= "\n";
  }
  return (\@lines);
}

sub r_graph {
  my @lines = @{$_[0]};
  my @names = @{$_[1]};
  my $outfile = $_[2];
  open (TXT, ">", "$outfile.txt") or die "Can't open txt outfile\n";

  print "Printing out results to $outfile.txt\n";

  for (my $i = 0; $i < @lines; $i++) {
    print TXT "$lines[$i]";
  } 

  close TXT;

  open (R, ">", "$outfile.R") or die "Can't open R outfile\n";

  print R "
library(ggplot2)
library(reshape)
pdf(file=\"$outfile.pdf\", family=\"Helvetica\", width=12, height=8)
plot<-read.table(\"$outfile.txt\", header=T)
plot.melt<-melt(plot[,c('percent', ";

  for (my $j = 0; $j < @names; $j++) {
    print R "'$names[$j]'";
    print R ", " unless ($j == @names - 1);
  }

  print R ")], id.vars=1)
ggplot(plot.melt, aes(x=percent, y=value, colour=variable, group=variable)) + 
geom_smooth() +
theme_bw() +
opts(title=\"Metaplot\", panel.grid.minor=theme_blank()) +
scale_colour_brewer(palette=\"Set1\", name=\"Bed\")";

  close R;

  `R --no-save < $outfile.R`;


}

sub phase_breakdown {
#  print "Phase breakdown simulations runs on G1, S1, S2, S3, S4, G2 only, in that order\n";
#  print "Enter bed files for G1-G2 in order, space-seperated:\n> ";
#  my $bedstr = <>;
#  chomp $bedstr;
#  my (@phases) = split(/\s/, $bedstr);
#  print "Enter the bedfile to compare against (ex. all origins)\n> ";
#  my $compare = <>;
#  chomp $compare;
#
#  $compare = $hash{$compare};

#  Make this an R script, after runnin genome sim or within regions sim on each file
  
}

sub corr_heatmap {
  print "Enter a space-seperated list of wigs to map\n> ";
  my $wigstr = <>;
  chomp $wigstr;
  my (@wig) = split (" ", $wigstr);
  print "Enter a peak file to map to\n> ";
  my $peaks = <>;
  chomp $peaks;
  print "Enter outfile name basename\n> ";
  my $out = <>;
  chomp $out; 

  my $bedname = basename($hash{$peaks}, ".bed");
  my $R = "
library(ggplot2)
library(reshape)
library(grid)
library(gridExtra)
library(miscTools)
";
  my $matrix = "matrix<-data.frame(";
  my $matrix_gene = "matrix_gene<-data.frame(";

  for (my $i = 0; $i < @wig; $i++) {
    my @suffixes = (".bedGraph.wig", ".wig");
    my $wigname = basename($hash{$wig[$i]}, @suffixes);
#    print "cmd is : perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -r /data/aparna/cache/ -w $hash{$wig[$i]} $hash{$peaks}\n"; 
    `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -c -m -r /data/aparna/cache/ -w $hash{$wig[$i]} $hash{$peaks}`; 
    $R .= "\n$wigname <- read.delim(\"..\/$wigname\_$bedname.txt\", header=F)\n$i<-$wigname\$V4\n";
    $R .= "\n$wigname\_genic <-read.delim(\"../$wigname\_hg19_gene_merged.txt\", header=F)\n$i\_genic<-$wigname\_genic\$V4\n";
    if ($i < @wig-1) {
      $matrix .= "$i,"; 
      $matrix_gene .= "$i\_genic,"; 
    }
    else {
      $matrix .= "$i)\n"; 
      $matrix_gene .= "$i\_genic)\n"; 
    }
  } 
  $R .= "$matrix\n$matrix_gene"; 
 
  $R .= "
melt<-melt(cor(matrix))

fileMedians<-colMedians(matrix)
genicMedians<-colMedians(matrix_gene)

avg<-rbind(fileMedians, genicMedians)

table<-tableGrob(round(avg, 2), vjust=-0.5, gp=gpar(fontsize=10))

p<-ggplot(data=melt, aes(x=X1, y=X2, fill = value)) +
geom_tile() + scale_fill_gradient2(limits=c(-1,1))+
geom_text(label=c(round(cor(matrix), 2)), colour = \"black\")+
ggtitle(\" \")+
theme(axis.title.x = element_blank(), axis.title.y = element_blank(), axis.text.x = element_text(angle = 90, hjust = 1))


plotboth<-arrangeGrob(p, table, nrow=2, heights=c(0.75,0.25))

pdf(\"$out\.pdf\")
plotboth
dev.off()    
";
open (OUT, ">", "out/$out.R");
print OUT $R;
close OUT; 


`cd out; R --no-save < $out.R`;
   
}

