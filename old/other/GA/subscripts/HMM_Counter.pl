#!/usr/bin/perl

use strict; use warnings; use FAlite; 
#use mitochy; 
use Getopt::Std;
use vars qw($opt_i $opt_r $opt_w $opt_o);
getopts("i:r:w:o:");

die "usage: $0 -i <fasta> -r <order> -w <words, comma separated> [Optional: -o <output>]

-i: Fasta file
-r: Order [integer 1,2,3,4]
-w: Words that HAS TO MATCH AND SAME ORDER AS stochhmm model file track symbol definition
-o: Output file (otherwise will be fa.count)

" unless defined($opt_i) and defined($opt_r) and defined($opt_w);

my ($input, $order, $words) = ($opt_i, $opt_r, $opt_w);
#my ($folder, $fileName)  = mitochy::getFilename($input, "folder");
my ($fileName) = $input =~ /\/{0,1}(.+)$/ ; # gets $fileName
my $output = defined($opt_o) ? $opt_o : "$fileName.count";
my @words = split(",", $words);

# Initialize Count tables. Don't mind the commented-out,
# these are for debug.
my @preword = @words;
# print "@preword\n";
for (my $i = 1; $i < $order; $i++) {
	my @curr;
	for (my $k = 0; $k < @preword; $k++) {
		for (my $j = 0; $j < @words; $j++) {
			push(@curr, "$preword[$k]$words[$j]");
#			print "$preword[$k]$words[$j]\n";
		}
	}
	@preword = @curr;
}

#for (my $i = 0; $i < keys %preword; $i++) {
my %count;
for (my $i = 0; $i < @preword; $i++) {
#	print "$preword[$i]\t";
	for (my $j = 0; $j < @words; $j++) {
		$count{$preword[$i]}{$words[$j]} = 0;
	}
}

# Create a table of probabilities based on fasta file.
open (my $in,  "<", $input) or die "Cannot read from $input: $!\n";
open (my $out, ">", $output) or die "Cannot write to $output: $!\n";
my $fasta = new FAlite($in);
while (my $entry = $fasta->nextEntry()) {
	my $seq = $entry->seq;
	$seq = uc($seq);
	my $def = $entry->def;
	for (my $i = $order; $i < length($seq); $i++) {
		my $subseq  = substr($seq, $i-$order, $order);
		my $current = substr($seq, $i, 1);
		$count{$subseq}{$current}++;
	}
}
close $in;

#debug
#for (my $i = 0; $i < @preword; $i++) {
#	for (my $j = 0; $j < @words; $j++) {
#		print "\t$words[$j]";
#	}
#	print "\n";
#	last;
#}

# Print out. If the count is 0, we make it 1 (can't have a 0 probability)
for (my $i = 0; $i < @preword; $i++) {
	for (my $j = 0; $j < @words; $j++) {
		$count{$preword[$i]}{$words[$j]} = 1 if $count{$preword[$i]}{$words[$j]} == 0;
		print $out "$count{$preword[$i]}{$words[$j]}\t";
		#print "$count{$preword[$i]}{$words[$j]}\t";
	}
	#print "\n";
	print $out "\n";
}
