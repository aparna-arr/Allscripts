#!/usr/bin/env perl
use warnings ;
use strict ;

my $warning = "
Warnings:
Expects ONE variableStep header per chrom
Expects SAME span for entire file
augments position with value in a hash
FIXME: Global %data hash that is not passed to function!
FIXME: Filenames extracted with /^(.+).wig/ so files need to be in same dir or else messed up outfile name!
Outfile: \"combined_\$name1_\$name2.wig\"

";

my ($wigfile1, $wigfile2) = @ARGV ;
die "usage: $0 <plus wig> <minus wig>\n$warning" unless @ARGV ;

print $warning ;

open (my $wig1, "<", $wigfile1) or die "Could not open $wigfile1\n" ;
open (my $wig2, "<", $wigfile2) or die "Could not open $wigfile2\n" ;

my $name1 = $wigfile1 =~ /^(.+).wig/ ;
my $name2 = $wigfile2 =~ /^(.+).wig/ ;

my %data ;

get_values(\$wig1) ;
close $wig1 ;

get_values(\$wig2) ;
close $wig2 ;

open (OUT, ">", "combined_$name1\_$name2.wig") or die "Could not open outfile\n" ;

foreach my $chrom (keys %data) {
  
  print OUT "variableStep chrom=$chrom span=$data{$chrom}{span}\n" ;   
  print "printing chrom $chrom\n" ;
  foreach my $pos (sort{$a<=>$b } keys %{ $data{$chrom}{values} } ) {
    print OUT "$pos\t$data{$chrom}{values}{$pos}\n" ;
  }
}

close OUT ;

print "\noutfile : combined_$name1\_$name2.wig\n\n" ;

sub get_values {

  my $ref = ${ $_[0] } ;
  my ($chr, $span)  = "INIT" ;

  while (<$ref>) {
    my $line = $_ ;
    chomp $line ;
  
    if ($line =~ /track/) {
      next ;
    }
    elsif ($line =~ /^variableStep/) {
      ($chr, $span) = $line =~ /^variableStep\schrom=(.+)\sspan=(.+)/ ;
      if (! exists($data{$chr})) {
        $data{$chr}{span} = $span ;
      }
    }
    else  {
      my ($pos, $val) = split(/\t/, $line) ;
      $data{$chr}{values}{$pos} += $val ;
    }

  }

}
