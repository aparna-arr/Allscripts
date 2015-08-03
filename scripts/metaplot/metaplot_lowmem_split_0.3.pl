#!/usr/bin/env perl

use warnings ;
use strict ;

control() ;

sub control {

  my $common_ref ; # reference to hash of chromosomes in both beds and wig
  my $results_ref ;

  my ($bed_ref, $name_ref, $wig_ref, $window, $test) = get_input() ; 
  ($bed_ref, $wig_ref, $common_ref) = split_files($bed_ref, $wig_ref) ; #re-uses refs

  if ($test == 0) { #ss
    ($results_ref) = process_ss($bed_ref, $wig_ref, $common_ref)  ; 
    print_results_ss($results_ref, $window, $name_ref) ; 
  } # if
  else { # normal
    ($results_ref) = process($bed_ref, $wig_ref, $common_ref) ; 
    print_results($results_ref, $window, $name_ref) ; 
  } # else

  r_graph($name_ref, $test) ;
}

sub get_input { 
  my (@input) = @ARGV ;
  die "usage: $0 -[options] <wig(s)> <maxwindow> <bed1> <name1> <bed2> <name2> ...\noptions:\n\ts : strand-specific. Input MUST be in this order:\n\t<pluswig> <minuswig> <maxwindow> <bed1plus> <bed1minus> <name1> ...\n\n\tIf Wigs and Beds are NOT in this order, the output will be wrong but there will be NO ERROR WARNING\n\n" unless @ARGV ;

  my $options ;
  my $test ; # indicates strand-specific if 0 normal if 1
  my @wigs ;
  my @beds ;
  my @nameAr ;
  my $maxwindow ;

  if ($input[0] =~ /^\-/) {
    $options = $input[0] ; 

    if ($options =~ /s/) {
      $wigs[0] = $input[1] ;
      $wigs[1] = $input[2] ;   
      $maxwindow = $input[3] ;
      $test = 0 ; # strand-specific beds

      for (my $n = 4 ; $n < @input ; $n++) {

        if ($n % 3 != 0) {
          push (@beds, $input[$n]) ;
        } # if
        else {
          push (@nameAr, $input[$n]) ;
        } # else

      } # for

    } # if

  } # if 
  else {
    $options = "NONE" ;
    $test = 1 ; # both strands in one bed file not strand-specific
    $wigs[0] = $input[0] ;
    $maxwindow = $input[1] ;

    for (my $m = 2 ; $m < @input ; $m++) {

      if ($m % 2 == 0) {
        push (@beds, $input[$m]) ;
      } # if
      else {
        push (@nameAr, $input[$m]) ;
      } # else

    } # for

  } # else
   
  validate(\@beds, \@nameAr, \@wigs, $test) ;
  return (\@beds, \@nameAr, \@wigs, $maxwindow, $test) ; #returning all refs
} # get_input ()

sub validate { 
  my @beds = @{ $_[0] } ;
  my @names = @{ $_[1] } ;
  my @wigs = @{ $_[2] } ;
  my $test = $_[3] ;

  foreach my $wig (@wigs) {
    if ($wig !~ /\.wig/) {
      die "Error! $wig is not a wigfile! See usage.\n" ;
    } # if 
  } # foreach

  foreach my $bed (@beds) {
    if ($bed !~ /\.bed/) {
      die "Error! $bed is not a bedfile! See usage.\n" ;
    } # if
  } # foreach

  if ($test == 0 && 2 * @names != @beds || $test == 1 && @names != @beds) {
    print "names = " . scalar(@names) . " beds = " . scalar(@beds) . "\n" ;
    die "Error! # names and # beds are not corresponding! See usage.\n" ;
  } # if
} # validate ()

sub split_files {  
  my @beds = @{ $_[0] } ; # array of original bed files
  my @wigs = @{ $_[1] } ; # array of original wig files
  my @bed_files ; # array of temp bed file names
  my @wig_files ; # array of temp wig file names
  my %temp_chrs ; # temporary chr list
  my %bed_chroms ; # list of chrs in bedfiles
  my %wig_chroms ; # list of chrs in wigfiles
  my %common ; # list of common chrs in bed and wig files

  `mkdir temp` ;
  print "\nSplitting up bedfiles\n" ;

  for (my $i = 0 ; $i < @beds ; $i++) {
    open (my $bed_fh, "<", $beds[$i]) or die "Can't open $beds[$i]\n" ;

    while (<$bed_fh>) {
      my $line = $_ ;
      chomp $line ;
      my ($chr) = $line =~ /^chr(\w+)/ ;

      if (!exists($bed_chroms{$chr})) {  # make a list of chrs in the bed files
        $bed_chroms{$chr} = 1 ; # arbitary value
      } # if
      
      $temp_chrs{$chr} .= $line . "\n" ;  # long string of all bed file lines for that chr
    } # while

    foreach my $chrom (keys %temp_chrs) {
      $bed_files[$i]{$chrom} = "temp/bed_$i\_$chrom.tmp" ; 
      open (my $fh_chrom, ">", "temp/bed_$i\_$chrom.tmp") ;
      print $fh_chrom $temp_chrs{$chrom} ;
      close $fh_chrom ;
    } # foreach

    %temp_chrs = () ; #clear list of chroms and lines for each bed file

    close $bed_fh ;
  } # for
  
  print "\nSplitting up wigfiles\n" ;

  for (my $j = 0 ; $j < @wigs ; $j++) {
    open (my $wig_fh, "<", $wigs[$j]) or die "Can't open $wigs[$j]\n";

    my $chr = "INIT" ;

    while (<$wig_fh>) {
      my $line = $_ ;

      if ($line =~ /^variableStep/) {
        ($chr) = $line =~ /chrom=chr(\w+)/ ; 

        if (!exists($wig_chroms{$chr}) ) { # make a list of chrs in wig files
          $wig_chroms{$chr} = 1 ; # arbitary value
        } # if

      } # if

      $temp_chrs{$chr} .= $line ;
    } # while  

    foreach my $chrom (keys %temp_chrs) {
      $wig_files[$j]{$chrom} = "temp/wig_$j\_$chrom.tmp" ;
      open (my $fh_chrom, ">", "temp/wig_$j\_$chrom.tmp") ;
      print $fh_chrom $temp_chrs{$chrom} ;
      close $fh_chrom ;
    } # foreach
    
    %temp_chrs = () ; #clear list of chroms and lines for each wig file
  
    close $wig_fh ;
  } # for

  foreach my $chrom (keys %bed_chroms) { # makes list of common chrs
    $common{$chrom} = 1 if exists $wig_chroms{$chrom} ; # arbitary value
  } # foreach

  print "\nDone pre-processing\n\n" ;
  return (\@bed_files, \@wig_files, \%common) ;
} # split_files ()

sub process { # normal
  my @bedfiles = @{ $_[0] } ;
  my @wigfiles = @{ $_[1] } ; 
  my %chromosomes = %{ $_[2] } ;
  my @results ; 

  print "Processing ...\n" ;

  foreach my $chrom (keys %chromosomes) {
    my @chrs ;

    for (my $i = 0 ; $i < @bedfiles ; $i++) {
      my $j = 0 ; 
      open (BED, "<", $bedfiles[$i]{$chrom}) ;

      while (<BED>) {
        my $line = $_ ;
        chomp $line ;
        my ($start, $end, $strand) = $line =~ /^chr\w+\t(\d+)\t(\d+)\t(.)/ ;
        $chrs[$i][$j]{start} = $start ;
        $chrs[$i][$j]{end} = $end ;
        $chrs[$i][$j]{strand} = $strand ;
        $j++ ;
      } # while

      close BED ; 
    } # for

    open(WIG, "<", $wigfiles[0]{$chrom}) ; 
    my %vals ;

    while(<WIG>) {
      my $line = $_ ;
      chomp $line ;

      my ($pos, $val) ;
      my $span = 0 ; 

      if ($line =~ /^variableStep/) {
        ($span) = $line =~ /span=(\d+)/ ; 
      } # if
      else {
        ($pos, $val) = $line =~ /(\d+)\t(\S+)/ ;

        for (my $n = $pos ; $n <= $pos + $span ; $n++) {
          $vals{$n} = $val ;
        } # for

      } # else

    } # while

    close WIG ;

    for (my $bedfile = 0 ; $bedfile < @chrs ; $bedfile ++) {

      for(my $num2 = 0 ; $num2 < @{ $chrs[$bedfile] } ; $num2++ ) {
        my $start = $chrs[$bedfile][$num2]{start} ;
        my $end = $chrs[$bedfile][$num2]{end} ;
        my $strand = $chrs[$bedfile][$num2]{strand} ;
        
        my $m ;
        my $k = 0 ;  
        my $l = $end - $start ;

        for ($m = $start ; $m <= $end ; $m++) {
 
          if ($strand eq '+') {

            if (exists($vals{$m})) {
              $results[$bedfile][$k]{height} += $vals{$m} ; 
              $results[$bedfile][$k]{count} ++ ;
            } # if 

            $k++ ; 
          } # if

          if ($strand eq '-') {

            if (exists($vals{$m})) {
              $results[$bedfile][$l]{height} += $vals{$m} ; 
              $results[$bedfile][$l]{count} ++ ;
            } # if

            $l-- ; 
          } # if 

        } # for 

      } # for 

    } # for 

    print "Got values for $chrom\n" ;

  } # foreach 

  print "\n" ;
  return(\@results) ;
} # sub process ()

sub process_ss { # strand specific
  my @bedfiles = @{ $_[0] } ;
  my @wigfiles = @{ $_[1] } ;
  my %chromosomes = %{ $_[2] } ;
  my @results ; 

  print "Processing ...\n" ;

  foreach my $chrom (keys %chromosomes) {
    my @chrs ;

## BED LOOP START ##

    for (my $i = 0 ; $i < @bedfiles ; $i++) {

      my $j = 0 ; # THIS IS INEFFICIENT but neccessary

      open (BED, "<", $bedfiles[$i]{$chrom}) ;

      while (<BED>) {
        my $line = $_ ;
        chomp $line ;
        my ($start, $end, $strand) = $line =~ /^chr\w+\t(\d+)\t(\d+)\t(.)/ ;
        $chrs[$i][$j]{start} = $start ;
        $chrs[$i][$j]{end} = $end ;
        $chrs[$i][$j]{strand} = $strand ;
        $j++ ;
      } # for

      close BED ; 
    } # while

## BED LOOP END ##

    my @vals ;

## WIG LOOP START ##

    for (my $k = 0 ; $k < @wigfiles ; $k++) {

      open(WIG, "<", $wigfiles[$k]{$chrom}) ;

      while(<WIG>) {
        my $line = $_ ;
        chomp $line ;
        my ($pos, $val) ;
        my $span = 0 ; 

        if ($line =~ /^variableStep/) {
          ($span) = $line =~ /span=(\d+)/ ; 
        } # if
        else {
          ($pos, $val) = $line =~ /(\d+)\t(\S+)/ ;

          for (my $n = $pos ; $n <= $pos + $span ; $n++) {
            $vals[$k]{$n} = $val ; 
          } # for

        } # else

      } # while

      close WIG ;
    } # for

## WIG LOOP END ##

    for (my $bedfile = 0 ; $bedfile < @chrs ; $bedfile+=2) { # PLUS BEDS
      # num2 = j = line number basically

      for(my $num2 = 0 ; $num2 < @{ $chrs[$bedfile] } ; $num2++ ) {
        my $start = $chrs[$bedfile][$num2]{start} ;
        my $end = $chrs[$bedfile][$num2]{end} ;
        my $o = 0 ; 

        for (my $m = $start ; $m <= $end ; $m++) {
          if (exists($vals[0]{$m})) { #PLUS wig
            $results[$bedfile][$o]{sense}{height} += $vals[0]{$m} ; 
            $results[$bedfile][$o]{sense}{count} ++ ;
          } # if 

          if (exists($vals[1]{$m})) { #MINUS wig 
            $results[$bedfile][$o]{antisense}{height} += $vals[1]{$m} ; 
            $results[$bedfile][$o]{antisense}{count} ++ ;
          } # if 

          $o++ ; 
        } # for

      } # for

    } # for

    for (my $bedfile2 = 1 ; $bedfile2 < @chrs ; $bedfile2 +=2) { # MINUS BEDS

      for (my $num3 = 0 ; $num3 < @{ $chrs[$bedfile2] } ; $num3++) {
        my $start2 = $chrs[$bedfile2][$num3]{start} ;
        my $end2 = $chrs[$bedfile2][$num3]{end} ;
        my $l2 = $end2 - $start2 ;

        for (my $m2 = $start2 ; $m2 <= $end2 ; $m2++) {
          if (exists($vals[1]{$m2})) { # MINUS wig
            $results[$bedfile2][$l2]{sense}{height} += $vals[1]{$m2} ;
            $results[$bedfile2][$l2]{sense}{height} ++ ;
          } # if

          if (exists($vals[0]{$m2})) { #PLUS wig
            $results[$bedfile2][$l2]{antisense}{height} += $vals[0]{$m2} ;
            $results[$bedfile2][$l2]{antisense}{height} ++ ;
          } # if
          
          $l2-- ;
        } # for

      } # for

    } # for

    print "Got values for $chrom\n" ; 
  } # foreach 

  return(\@results) ;
} # sub process_ss ()

sub print_results {
  my @data = @{ $_[0] } ;
  my $x = $_[1]  ;
  my @names = @{ $_[2] } ;
  my $head = join("\t", @names) ;
  my $h = 0 - ($x / 2) ;

  open (OUT, ">", "metaplot_outfile.txt") or die "Can't open outfile\n" ;

  print "\nPrinting out results\n\n" ;
  print OUT "bp\t$head\n" ;

  for (my $i = 0 ; $i <= $x ; $i++) {
    print OUT $h + $i, "\t" ;

    for (my $n =0 ; $n < @data ; $n++) {

      if (!exists($data[$n][$i]{count})) {
        print OUT "NA\t" ;
      } # if
      else {
        my $avg = $data[$n][$i]{height} / $data[$n][$i]{count} ;
        print OUT "$avg\t" ;
      } # else

    } # for

    print OUT "\n" ;
  }

  close OUT ;
} #sub print_results

sub print_results_ss {
  my @data = @{ $_[0] } ;
  my $x = $_[1] ;
  my @names = @{ $_[2] } ;
  my $head ;
  my $h = 0 - ($x / 2) ;
  
  open (OUT, ">", "metaplot_outfile.txt") or die "Can't open outfile\n" ;
  print "\nPrinting out results\n\n" ;

  for (my $w = 0 ; $w < @names ; $w++) {
    $head = $head . "$names[$w]\_sense\t$names[$w]\_antisense\t" ;
  } # for

  print OUT "bp\t$head\n" ;

  for (my $i = 0 ; $i <= $x ; $i++) {
    print OUT $h + $i, "\t" ;


    for (my $n = 0 ; $n < @data ; $n+=2) {  

      ## SENSE ## 

      if (!exists($data[$n][$i]{sense}{count}) && !exists($data[$n+1][$i]{sense}{count})) {
        print OUT "NA\t" ;
      } # if
      else { # does exist in at least 1
        my $avg ;

        if (exists($data[$n][$i]{sense}{count}) && exists($data[$n+1][$i]{sense}{count})) {
          $avg = ($data[$n][$i]{sense}{height} + $data[$n+1][$i]{sense}{height}) / ($data[$n][$i]{sense}{count} + $data[$n+1][$i]{sense}{count}) ;
        } # if
        elsif (!exists($data[$n][$i]{sense}{count})) {
          $avg = $data[$n+1][$i]{sense}{height} / $data[$n+1][$i]{sense}{count} ; 
        } # elsif
        elsif (!exists($data[$n+1][$i]{sense}{count})) {
          $avg = $data[$n][$i]{sense}{height} / $data[$n][$i]{sense}{count} ; 
        } # elsif

        print OUT "$avg\t" ;
      } # else

      ## ANTISENSE ##

      if (!exists($data[$n][$i]{antisense}{count}) && !exists($data[$n+1][$i]{antisense}{count})) {
        print OUT "NA\t" ;
      } # if
      else { # does exist in at least 1
        my $avg ;

        if (exists($data[$n][$i]{antisense}{count}) && exists($data[$n+1][$i]{antisense}{count})) {
          $avg = ($data[$n][$i]{antisense}{height} + $data[$n+1][$i]{antisense}{height}) / ($data[$n][$i]{antisense}{count} + $data[$n+1][$i]{antisense}{count}) ;
        } # if
        elsif (!exists($data[$n][$i]{antisense}{count})) {
          $avg = $data[$n+1][$i]{antisense}{height} / $data[$n+1][$i]{antisense}{count} ; 
        } # elsif
        elsif (!exists($data[$n+1][$i]{antisense}{count})) {
          $avg = $data[$n][$i]{antisense}{height} / $data[$n][$i]{antisense}{count} ; 
        } # elsif

        $avg = $avg * -1 ;
        print OUT "$avg\t" ;
      } # else   

    } # for

    print OUT "\n" ;
  } # for

  close OUT ;
} # sub print_results_ss ()


sub r_graph {
  my @names = @{ $_[0] } ;
  my $test = $_[1] ;

  open (R, ">", "metaplot_outfile.R") or die "Can't open R outfile\n" ;
  
  print R "library(ggplot2)\n" ;
  print R "library(reshape)\n" ;
  print R "pdf(file=\"metaplot_outfile.pdf\", family=\"Helvetica\", width=12, height=8)\n" ;
  print R "plot<-read.table(\"metaplot_outfile.txt\", header=T)\n" ;
  print R "plot.melt <- melt(plot[,c('bp', " ;

  if ($test == 0) { # strand-specific

    for (my $w = 0 ; $w < @names ; $w++) {
      print R "'$names[$w]_sense', '$names[$w]_antisense'" ;
      print R ", " unless ($w == @names - 1) ;
    } # for

  } # if
  else {

    for (my $w = 0 ; $w < @names ; $w++) {
      print R "'$names[$w]'" ;
      print R ", " unless ($w == @names - 1) ;
    } # for

  } # else

  print R ")], id.vars=1)\n" ;
  print R "ggplot(plot.melt, aes(x=bp, y=value, colour=variable, group=variable)) + geom_smooth() + theme_bw() + opts(title=\"Metaplot\", panel.grid.minor=theme_blank()) + scale_colour_brewer(palette=\"Set1\", name=\"Bed\")\n" ;

  close R ;

  `R --no-save < metaplot_outfile.R` ;
  `rm temp/*` ;
  `rmdir temp` ;
} #sub r_graph ()











 
