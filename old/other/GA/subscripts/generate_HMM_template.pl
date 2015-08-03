#!/usr/bin/env perl
use warnings;
use strict;

my ($outfile) = @ARGV;
die "usage: $0 <outfile name>\n" unless @ARGV == 1;

#my $input = <STDIN>; # this is neccessary because otherwise the first
                # <STDIN> operator tries to read the cli argument
                # and skips user input 
print "Script to generate HMM template model.\n";
open (OUT, ">", $outfile) or die "Could not open $outfile\n";

print OUT "\#STOCHHMM MODEL FILE\n";
print OUT "MODEL INFORMATION\n";
print OUT "="x54;
print OUT "\nMODEL_NAME:\t";

print "MODEL_NAME:\t";
my $input = <STDIN>;

print OUT $input;

print OUT "MODEL_DESCRIPTION:\t";
print "MODEL_DESCRIPTION:\t";
$input = <STDIN>;

print OUT $input;

print OUT "MODEL_CREATION_DATE:\t";
print "MODEL_CREATION_DATE:\t";
$input = <STDIN>;

print OUT $input;

print "Order? : ";
my $order = <STDIN>;
chomp $order;

print OUT "\nTRACK SYMBOL DEFINITIONS\n";
print OUT "="x54;
print OUT "\n";

print "Emission name?(ex. SCORE) : ";
my $emmname = <STDIN>;
chomp $emmname;

print OUT "$emmname:\t";

print "Emission type?(ex. COUNTS) : ";
my $emmtype = <STDIN>;
chomp $emmtype;

print "Emissions?(ex. N L M H) : ";
#my (@emms) = split(/\s/, <STDIN>);

my @emms = split(/\s/, <STDIN>);

print OUT join(",", @emms) . "\n\n";
print OUT "STATE DEFINITIONS\n";
print OUT "\#"x45 . "\n";

print "States?(ex. BROAD_PEAK SMALL_PEAK) : ";
my @states = split(/\s/, <STDIN>);

print OUT "STATE:\n";
print OUT "\tNAME:\tINIT\n";
print OUT "TRANSITION:\tSTANDARD:\tP(X)\n";

my $init_em = 1/@states;

for (my $i = 0; $i < @states; $i++) {
  print OUT "\t$states[$i]:\t$init_em\n";
}

print OUT "\#"x45 . "\n";

for (my $j = 0; $j < @states; $j++) {

  print "\nOn $states[$j] of [" . join(",", @states) . "]\n";
  print OUT "STATE:\n";
  print OUT "\tNAME:\t$states[$j]\n";
  print OUT "\tPATH_LABEL:\t";

  print "PATH_LABEL:\t";
  $input = <STDIN>;
  print OUT $input;

  print "GFF_DESC (ENTER if none) : \t";
  $input = <STDIN>;
  chomp $input;

  if ($input ne "") {
    print OUT "\tGFF_DESC\t$input\n";
  }

  print OUT "TRANSITION:\tSTANDARD:\tP(X)\n";

  print "\nTransition probabilities (must add to 1!)\n0 if no transition to that state\n";
  my $confirm = "n";
  my @transitions;
  do {
    @transitions = ();

    for (my $n = 0; $n < @states; $n++) {
      my $tr;
      print "$states[$n]: ";
      $tr = <STDIN>;
      chomp $tr;
      push (@transitions, $tr);
    }

    print "\nTransition probabilities are:\n";

    for (my $m = 0 ; $m < @states ; $m++) {
      print "$states[$m]: $transitions[$m]\n";
    }

    print "Confirm (y/n)? : ";
    $confirm = <STDIN>;
  } while ($confirm !~ /y|Y/);

  for (my $m = 0 ; $m < @states ; $m++) {
    print OUT "\t$states[$m]:\t$transitions[$m]\n";
  }
  
  print OUT "\tEND:\t1\n";
  print OUT "EMISSION:\t$emmname\t$emmtype\n";
  print OUT "\tORDER:\t$order\n";
  print OUT "@" . join("\t", @emms) . "\n";
  print OUT "\#"x45 . "\n";
}

print OUT "//END";

close OUT;

print "HMM Template is $outfile\n";
