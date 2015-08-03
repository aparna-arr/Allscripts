#!/usr/bin/env perl
use warnings;
use strict;

# 10 regions of 300 bp
# 5 in early replication regions, no R-Loop, no ori
# 5 on early ori, no R-Loop

my ($early_rep, $ori, $dripdripcmerge, $outfile) = @ARGV;
die "usage: <early replication region> <oris> <DRIP DRIPc merge> <outfile>\n" unless @ARGV;

# 100 random regions of size 300 bp #
`bedtools random -l 300 -n 100 -g /data/aparna/Data/hg19.genome > random.tmp`;

`cat $dripdripcmerge $ori /data/aparna/Data/gaps_hg19.bed > exclude_rloop_ori.tmp`;
`cat $dripdripcmerge /data/aparna/Data/gaps_hg19.bed > exclude_rloop.tmp`;
`bedtools intersect -u -a $ori -b $early_rep > early_ori.tmp`;

# shuffle on early replication regions with no R-Loop no Ori #
  `bedtools shuffle -i random.tmp -incl $early_rep -g /data/aparna/Data/hg19.genome > shuffle_no-rloop_no-ori.tmp`;
  `bedtools intersect -v -a shuffle_no-rloop_no-ori.tmp -b $ori > shuffle_no-rloop_no-ori.bed`;
  `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -r /data/aparna/cache -w /data/aparna/Data/K562/LS42B_all.wig shuffle_no-rloop_no-ori.bed`;
  `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -r /data/aparna/cache -w /data/aparna/Data/K562/LS42C_treat_afterfiting_all.wig LS42B_all_shuffle_no-rloop_no-ori.txt`;
# shuffle on early replication region oris with no R-loop #
  `bedtools shuffle -i random.tmp -incl early_ori.tmp -g /data/aparna/Data/hg19.genome > shuffle_no-rloop.bed`;
  `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -r /data/aparna/cache -w /data/aparna/Data/K562/LS42B_all.wig shuffle_no-rloop.bed`;
  `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -r /data/aparna/cache -w /data/aparna/Data/K562/LS42C_treat_afterfiting_all.wig LS42B_all_shuffle_no-rloop.txt`;

# map no-rloop no-ori regions
  # find early replication regions with no Rloop no Ori with <5 count
  open (OUT, ">", $outfile) or die;
  print OUT "\# No Rloop No Ori\n";
  my $i = 10;
  open(IN, "<", "LS42C_treat_afterfiting_all_LS42B_all_shuffle_no-rloop_no-ori.txt") or die;
  while (<IN>)
  {
    my $line = $_;
    chomp $line;
    
    my ($chr, $start, $end, $drip, $dripc, $trash) = split(/\s+/, $line);

    if ($drip < 5 && $dripc < 5)
    {
      print "$chr\t$start\t$end\t$drip\t$dripc\n";
      print OUT "$chr\t$start\t$end\n";
      $i--;
    }
  
    if ($i == 0)
    {
       last;
    }
  }

#no rloop only
  print "\n";
  print OUT "\# No Rloop\n";
  $i = 10;
  open(IN, "<", "LS42C_treat_afterfiting_all_LS42B_all_shuffle_no-rloop.txt") or die;
  while (<IN>)
  {
    my $line = $_;
    
    chomp $line;
   
#    print "line is [$line]\n"; 
    my ($chr, $start, $end, $drip, $dripc, $trash) = split(/\s+/, $line);
#    print "chr [$chr] start [$start] end [$end] drip [$drip] dripc [$dripc]\n";

    if ($drip < 5 && $dripc < 5)
    {
      print "$chr\t$start\t$end\t$drip\t$dripc\n";
      print OUT "$chr\t$start\t$end\n";
      $i--;
    }
    if ($i ==0)
    {
      last;
    }
  }


