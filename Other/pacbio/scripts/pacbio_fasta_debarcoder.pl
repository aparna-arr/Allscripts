#!/usr/bin/perl
# debarcoder for pacbio fasta ccs reads

use strict; use warnings;
use Getopt::Std;
use FileHandle;
use FAlite;

die "usage: pacbio_fasta_debarcoder.pl <fasta> <prefix>\n" unless @ARGV == 2;
my $prefix = $ARGV[1];

open(IN, $ARGV[0]) or die "error reading $ARGV[0]\n";
my $fasta = new FAlite(\*IN);

my %barcode;

$barcode{"GCGCTCTGTGTGCAGC"} = "1F";
$barcode{"TCATATGTAGTACTCT"} = "1R";
$barcode{"TCATGAGTCGACACTA"} = "2F";
$barcode{"GCGATCTATGCACACG"} = "2R";
$barcode{"TATCTATCGTATACGC"} = "3F";
$barcode{"TGCAGTCGAGATACAT"} = "3R";
$barcode{"ATCACACTGCATCTGA"} = "4F";
$barcode{"GACTCTGCGTCGAGTC"} = "4R";
$barcode{"ACGTACGCTCGTCATA"} = "5F";
$barcode{"TACAGCGACGTCATCG"} = "5R";
$barcode{"TGTGAGTCAGTACGCG"} = "6F";
$barcode{"GCGCAGACTACGTGTG"} = "6R";

#my %count;
#my %FH;

my $barcode_length = 16;
my $barcode_length_2 = -16;

my $out1 = $prefix . "_left.fa";
my $out2 = $prefix . "_right.fa";

open (LEFT, ">", $out1);
open (RIGHT, ">", $out2);

while (my $entry = $fasta->nextEntry)
{
    my $id = $entry->def;
    my $seq = $entry->seq;
    my ($bc) = substr($seq, 0, $barcode_length); # first barcode at the first end
    my ($bc2) = substr($seq, $barcode_length_2); # second barcode at the right end
    print LEFT "$id\n$bc\n";
    print RIGHT "$id\n$bc2\n";

   # if (defined $barcode{$bc})
    #{
     #   print "$bc\t$barcode{$bc}\n";
    #}
    #else
    #{
     #   print "$bc\tno match\n";
    #}
}

close IN;


__END__


while (my $line = <$in>)
{
	chomp $line;

	my $line2 = <$in>;
	chomp $line2;
	$barcode = substr($line2, 0, 6);	# read what the barcode is
	$line2 = substr($line2, 7);	# trim of 7 bases (barcode + T overhang)

	<$in>; # line 3 is not important, just repeating ID
	my $line3 = "+";

	my $line4 = <$in>;
	chomp $line4;
	$line4 = substr($line4, 7);	# trim of 7 quality scores

	if (!exists $FH{$barcode})	# see barcode for the first time, open a new file
	{
		$FH{$barcode} = new FileHandle;
		$FH{$barcode}->open(">$barcode\.fastq");
		$FH{$barcode}->print("$line1\n$line2\n$line3\n$line4\n");
	}

	else
	{
		$FH{$barcode}->print("$line1\n$line2\n$line3\n$line4\n");
	}

	$count{$barcode}++;
}

foreach $barcode (sort {$count{$b} <=> $count{$a}} keys %count)
{
	print OUT "$barcode	$count{$barcode}\n";
}
