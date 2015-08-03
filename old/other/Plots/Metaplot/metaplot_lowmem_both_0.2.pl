#!/usr/bin/env perl

use warnings ;
use strict ;

control() ;

sub control {
  my $common_ref ;
  my ($wig_ref, $bed_ref, $name_ref) = get_input() ; 
  ($bed_ref, $wig_ref, $common_ref) = split_files($wig_ref, $bed_ref) ; 
  my ($results_ref, $x) = process($wig_ref, $bed_ref, $common_ref) ; 
  print_results($results_ref, $x, $name_ref) ;
  r_graph($name_ref) ;
}

sub get_input {
  my ($wigfile, @bednames) = @ARGV ;
  die "usage : wig bedfile1 name1 bedfile2 name2 ...\n" unless @ARGV ;

  my @bedfiles ;
  my @names ;
  my $i ;

  for ($i = 0 ; $i < @bednames ; $i ++) {
    if ($i % 2 == 0) {
      push (@bedfiles, $bednames[$i]) ;
    }
    else {
      push (@names, $bednames[$i]) ;
    }
  }
  foreach my $beds (@bedfiles) {
    if ($beds !~ /.bed/) {
      die "Error! $beds is not a bedfile! See usage.\n"
    }
  }
  return (\$wigfile, \@bedfiles, \@names) ; #returning all refs
}

sub split_files {
  my $wig = ${ $_[0] } ;
  my @beds = @{ $_[1] } ;
  my @bed_files ;
  my %chromosomes ;
  my %common ;
  my $i ;
  my %wig_chroms ;
  my %wig_files ; 
  my $chr_wig = "INIT" ;

  `mkdir temp` ;
  print "\nSplitting up bedfiles " ;

  for ($i = 0 ; $i < @beds ; $i++) {
    open (my $bed_fh, "<", $beds[$i]) or die "Can't open $beds[$i]\n" ;

    while (<$bed_fh>) {
      my $line = $_ ;
      chomp $line ;
      my ($chr) = $line =~ /^chr(\w+)/ ;

      if (! exists($chromosomes{$chr})) { 
        $chromosomes{$chr} = $line . "\n";
      }
      else {
        $chromosomes{$chr} .= $line . "\n";  
      }
    }

    foreach my $chrom (keys %chromosomes) {
      $bed_files[$i]{$chrom} = "temp/bed_$i\_$chrom.tmp" ; #array of hashes
      open (my $fh_chrom, ">", "temp/bed_$i\_$chrom.tmp") ;
      print $fh_chrom $chromosomes{$chrom} ;
      close $fh_chrom ;
    }

    close $bed_fh ;
  }
  
  print "\nSplitting up wigfile $wig\n" ;
  open (my $wig_fh, "<", $wig) or die "Can't open $wig\n";

  while (<$wig_fh>) {
    my $line = $_ ;

    if ($line =~ /^variableStep/) {
    ($chr_wig) = $line =~ /chrom=chr(\w+)/ ; 

      if (! exists($wig_chroms{$chr_wig}) ) {
        $wig_chroms{$chr_wig} = $line ;  
      }
      else {
        $wig_chroms{$chr_wig} .= $line ;  
      }
    }
    else {
      $wig_chroms{$chr_wig} .= $line ; # for non-variableStep lines 
    }
  }  

  foreach my $chrom_wig (keys %wig_chroms) {
    $wig_files{$chrom_wig} = "temp/wig_$chrom_wig.tmp" ;
    open (my $fh_chrom, ">", "temp/wig_$chrom_wig.tmp") ;
    print $fh_chrom $wig_chroms{$chrom_wig} ;
    close $fh_chrom ;

    $common{$chrom_wig} = "" if exists $chromosomes{$chrom_wig} ; # list of chrs
  }

  close $wig_fh ;
  print "\nDone pre-processing\n\n" ;
  return (\@bed_files, \%wig_files, \%common) ;
}

sub process {
  my %wigfiles = %{ $_[0] } ;
  my @bedfiles = @{ $_[1] } ;
  my %chromosomes = %{ $_[2] } ;
  my @results ; 
  my $i ;
  my $x ;

  print "Got values for " ;

  foreach my $chrom (keys %chromosomes) {
    my @chrs ;

    for ($i = 0; $i < @bedfiles ; $i ++) {
      my $num = 0;
      open (BED, "<", $bedfiles[$i]{$chrom}) ;

      while (<BED>) {
        my $line = $_ ;
        chomp $line ;
        my ($start, $end, $strand) = $line =~ /^chr\w+\t(\d+)\t(\d+)\t(.)/ ;
        $chrs[$i][$num]{start} = $start ;
        $chrs[$i][$num]{end} = $end ;
        $chrs[$i][$num]{strand} = $strand ;
        $num ++ ;
      }

      close BED ; 
    }

    open(WIG, "<", $wigfiles{$chrom}) ;
    my %vals2 ;

    while(<WIG>) {
      my $line = $_ ;
      chomp $line ;
      my ($pos, $val) ;
      my $span = 0 ; 

      if ($line =~ /^variableStep/) {
        ($span) = $line =~ /span=(\d+)/ ; 
      }
      else 
      {
        ($pos, $val) = $line =~ /(\d+)\t(\S+)/ ;
        my $n ;

        for ($n = $pos ; $n <= $pos + $span ; $n++) {
          $vals2{$n} = $val ;
        }
      }
    }
    close WIG ;

    for (my $bedfile = 0 ; $bedfile < @chrs ; $bedfile ++) {

      for(my $num2 = 0 ; $num2 < @{ $chrs[$bedfile] } ; $num2++ ) {
        my $start = $chrs[$bedfile][$num2]{start} ;
        my $end = $chrs[$bedfile][$num2]{end} ;
        my $strand = $chrs[$bedfile][$num2]{strand} ;
        
        my $m ;
        $x = 1 ;
        my $k = 1 ;
        my $l = $end - $start ;

        for ($m = $start ; $m <= $end ; $m++) {

          if ($strand eq '+') {

            if (exists($vals2{$m})) {
              $results[$bedfile][$k]{height} += $vals2{$m} ; #FIX data struct
              $results[$bedfile][$k]{count} ++ ;
            } # if val exists

            $k++ ; 
          } #if strand +

          if ($strand eq '-') {

            if (exists($vals2{$m})) {
              $results[$bedfile][$l]{height} += $vals2{$m} ; #FIX data struct
              $results[$bedfile][$l]{count} ++ ;
            } #if val exists

            $l-- ; 
          } #if strand -

          $x++ ; 
        } #for loop start end
      } #for num2
    } # for bedfile

    print "$chrom " ;
  } # foreach chrom
  print "\n" ;
  return(\@results, $x) ;
} # sub process

sub print_results {
  my @data = @{ $_[0] } ;
  my $x = $_[1]  ;
  my @names = @{ $_[2] } ;
  open (OUT, ">", "metaplot_outfile.txt") or die "Can't open outfile\n" ;
  print "\nPrinting out results\n\n" ;
  
  my $head = join("\t", @names) ;
  print OUT "bp\t$head\n" ;
  my $h = 0 - ($x / 2) ;

  for (my $i = 1 ; $i < $x ; $i++) {
    print OUT $h + $i, "\t" ;

    for (my $n =0 ; $n < @data ; $n++) {

      if (! exists($data[$n][$i]{count})) {
        print OUT "NA\t" ;
      }
      else {
        my $avg = $data[$n][$i]{height} / $data[$n][$i]{count} ;
        print OUT "$avg\t" ;
      }
    }

    print OUT "\n" ;
  }

  close OUT ;
} #sub print_results

sub r_graph {
  my @names = @{ $_[0] } ;
  open (R, ">", "metaplot_outfile.R") or die "Can't open R outfile\n" ;
  
  print R "library(ggplot2)\n" ;
  print R "library(reshape)\n" ;
  print R "pdf(file=\"metaplot_outfile.pdf\", family=\"Helvetica\", width=12, height=8)\n" ;
  print R "plot<-read.table(\"metaplot_outfile.txt\", header=T)\n" ;
  print R "plot.melt <- melt(plot[,c('bp', " ;

  for (my $w = 0 ; $w < @names ; $w++) {
    print R "'$names[$w]'" ;
    print R ", " unless ($w == @names - 1) ;
  }

  print R ")], id.vars=1)\n" ;
  print R "ggplot(plot.melt, aes(x=bp, y=value, colour=variable, group=variable)) + geom_smooth() + theme_bw() + opts(title=\"Metaplot\", panel.grid.minor=theme_blank()) + scale_colour_brewer(palette=\"Set1\", name=\"Bed\")\n" ;

  close R ;
  `R --no-save < metaplot_outfile.R` ;
  `rm temp/*` ;
  `rmdir temp` ;
} #sub r_graph











 
