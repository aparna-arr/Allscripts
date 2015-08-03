#!/usr/bin/perl
# a step in pacbio read debarcoding

use strict; use warnings;
use Getopt::Std;
use FileHandle;
use FAlite;

die "usage: match_barcode.pl <barcode file> <matching fasta>\n" unless @ARGV == 2;

open(IN, $ARGV[0]) or die "error reading $ARGV[0]\n";

my $i = 0;  # count for each fasta entry
my @barcode;

while (my $line = <IN>)
{
    chomp $line;
    my @stuff = split("\t", $line);
    my $bc1 = substr($stuff[1], 0, 1);
    my $bc2 = substr($stuff[2], 0, 1);

    if ($line =~ m/\*\t\*/)
    {
        $barcode[$i] = "unknown";
    }

    elsif ($bc1 eq $bc2)
    {
        $barcode[$i] = $bc1;
    }

    elsif ($stuff[1] eq "*")
    {
        $barcode[$i] = $bc2;
    }

    elsif ($stuff[2] eq "*")
    {
        $barcode[$i] = $bc1;
    }

    elsif ($bc1 ne $bc2)
    {
        $barcode[$i] = "unknown";
    }
    else
    {
        die "error, can't decipher barcode\n";
    }
    $i++;
}

close IN;

# for (my $j = 0; $j < @barcode; $j++)
# {
#     print "$j\t$barcode[$j]\n";
# }

open (IN2, $ARGV[1]) or die "error opening fasta file\n";

my $fasta = new FAlite(\*IN2);
my %FH;
my $k = 0;  # matching fasta entry count
my %count;  # keep track of how many reads each barcode has

while (my $entry = $fasta->nextEntry)
{
    my ($id) = $entry->def;
    my ($seq) = $entry->seq;
    next if length($seq) < 36;  # the read is too short!
    # need to remove 16 from the beginning and end of the read
    my ($debarcoded) = substr($seq, 16, -16);

    if (!exists $FH{$barcode[$k]})	# see barcode for the first time, open a new file
	{
		$FH{$barcode[$k]} = new FileHandle;
		my $outname = "bc_" . $barcode[$k] . ".fa";
		$FH{$barcode[$k]}->open(">$outname");
		$FH{$barcode[$k]}->print("$id\n$debarcoded\n");
	}

	else
	{
		$FH{$barcode[$k]}->print("$id\n$debarcoded\n");
	}

	$count{$barcode[$k]}++;
	$k++;
}

close IN2;

foreach my $bar (sort {$count{$b} <=> $count{$a}} keys %count)
{
	print "$bar\t$count{$bar}\n";
}




__END__







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
