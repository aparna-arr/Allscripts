#!/usr/bin/perl
# VERSION 3 March 2015
# dripc_promoter.shuffled is in /data/mitochi/Work/Project/DRIPc/4_Chromatin/1_Shuffle/Result_125/dripc_promoter.shuffled
use strict; use warnings; use mitochy; use Getopt::Std; use R_toolbox; use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use vars qw($opt_r $opt_i $opt_a $opt_b $opt_g $opt_n);
getopts("r:i:a:b:g:n");

print RED "\n0. Sanity Check\n";
preCheck();

my ($rnaFile, $origFile, $shufFile) = ($opt_r, $opt_a, $opt_b);
my $graphScript = defined($opt_g) ? $opt_g : "Graph_4Exp.pl";
die RED "Graph Script File $opt_g does not exist!\n" if not -e $graphScript;
my ($folder1, $fileNameOrig) = mitochy::getFilename($origFile, "folder");
my ($folder2, $fileNameShuf) = mitochy::getFilename($shufFile, "folder");

print "1. Parsing RNA file $rnaFile\n";
my %rna = %{parse_rna($rnaFile)};

print "2. Dividing Original tsv $origFile into 4 expression quartiles (e.g. $fileNameOrig\_super.temp)\n";
open (my $outsuper1,  ">", "$fileNameOrig\_super.temp")	or die "Cannot write to $fileNameOrig\_super.temp: $!\n";
open (my $outhigh1,   ">", "$fileNameOrig\_high.temp")  or die "Cannot write to $fileNameOrig\_high.temp: $!\n";
open (my $outmed1,    ">", "$fileNameOrig\_med.temp")	or die "Cannot write to $fileNameOrig\_med.temp: $!\n";
open (my $outlow1,    ">", "$fileNameOrig\_low.temp")	or die "Cannot write to $fileNameOrig\_low.temp: $!\n";
open (my $in, "<", $origFile) or die "Cannot read from $origFile: $!\n";
while (my $line = <$in>) {
	chomp($line);
	next if $line =~ /#/;
	my ($name) = split("\t", $line);
	my $rna = defined($rna{$name}) ? $rna{$name} : 0;
	$line =~ s/\tNA/\t0/g if not $opt_n;
	print $outsuper1  "$line\n" if $rna >= 200;
	print $outhigh1   "$line\n" if $rna >= 100 and $rna < 200;
	print $outmed1    "$line\n" if $rna >= 50 and $rna < 100;
	print $outlow1    "$line\n" if $rna >= 10 and $rna < 50;
}
close $in;

print "3. Dividing Shuffled tsv $shufFile into 4 expression quartiles (e.g. $fileNameShuf\_super.temp)\n";
open (my $outsuper2,  ">", "$fileNameShuf\_super.temp")  or die "Cannot write to $fileNameShuf\_super.temp: $!\n";
open (my $outhigh2,   ">", "$fileNameShuf\_high.temp")  or die "Cannot write to $fileNameShuf\_high.temp: $!\n";
open (my $outmed2,    ">", "$fileNameShuf\_med.temp")  or die "Cannot write to $fileNameShuf\_med.temp: $!\n";
open (my $outlow2,    ">", "$fileNameShuf\_low.temp")  or die "Cannot write to $fileNameShuf\_low.temp: $!\n";
open (my $in2, "<", $shufFile) or die "Cannot read from $shufFile: $!\n";
while (my $line = <$in2>) {
	chomp($line);
	next if $line =~ /#/;
	my ($name) = split("\t", $line);
	my $rna = defined($rna{$name}) ? $rna{$name} : 0;
	$line =~ s/\tNA/\t0/g if not $opt_n;
	print $outsuper2  "$line\n" if $rna > 200;
	print $outhigh2   "$line\n" if $rna <= 200 and $rna > 100;
	print $outmed2    "$line\n" if $rna >= 50 and $rna < 100;
	print $outlow2    "$line\n" if $rna >= 10 and $rna < 50;
}
close $in2;

print "4. Running $graphScript\n";
runbash("perl -I /usr/local/bin/Perl Graph_4Exp.pl $fileNameOrig\_high.temp");
# This looks like it's only running 1 file, but it's taking the name of that file and running other 4 files that has the same name

sub parse_rna {
        my ($input) = @_;
        my %data;
        open (my $in, "<", $input) or die "Cannot read from $input: $!\n";
        while (my $line = <$in>) {
                chomp($line);
                next if $line =~ /#/;
                my ($gene, $val) = split("\t", $line);
                $data{$gene} = $val;
        }
        close $in;
        return(\%data);
}

sub parse_peak {
	my ($input) = @_;
	my %data;
	my %used;
	# Parse the bedfile
	open (my $in1, "<", $input) or die "Cannot read from $input: $!\n";
	while (my $line = <$in1>) {
		chomp($line);
		next if $line =~ /#/;
		my ($chr, $start, $end, $name, $val, $strand, $info) = split("\t", $line);
		my ($orig, $shuf) = $info =~ /ORIG=(\w+\.\d+),chr.+TWIN=(\w+\.\d+),chr/;
		die "Undefined twin gene at line: $line\n" if not defined($shuf);
		push(@{$data{orig}{$orig}{temp}}, $shuf);
		next if defined($used{$name}) and $used{$name} == 1;
		$data{orig}{$orig}{count} ++;
		$data{name}{$name} = $orig;
		$used{$name} = 1;
	}
	
	close $in1;

	# randomize array and take first 10
	foreach my $name (keys %{$data{orig}}) {
		my @value = shuffle(@{$data{orig}{$name}{temp}});
		@{$data{orig}{$name}{temp}} = ();
		for (my $i = 0; $i < @{$data{orig}{$name}{temp}}; $i++) {
			$data{shuf}{$value[$i]}{$name} ++;
		}
		@value = ();
	}
	return(\%data);
}

sub shuffle {
        my (@value) = @_;
	my $shuffleTimes = @value < 1000 ? 1000 : @value;
        for (my $i = 0; $i < $shuffleTimes; $i++) {
                my $rand1 = int(rand(@value));
                my $rand2 = int(rand(@value));
                my $val1 = $value[$rand1];
                my $val2 = $value[$rand2];
                $value[$rand1] = $val2;
                $value[$rand2] = $val1;
        }
        return(@value);
}

sub runbash {
        my ($cmd) = @_;
        print "\t$cmd\n";
        system($cmd) == 0 or die "Failed to run $cmd: $!\n";
}

sub preCheck {
	my $usage = "
usage: $0 [Options] -r <RNAseq> -a <orig.tsv e.g. MCF_groseq_promoter_orig.tsv> -b <shuf.tsv>

Options:
-n: Don't convert NAs into 0
-g: Use this Graph.pl file (Default: Graph_4exp.pl) 

E.g. :
	$0 -r K562.rpkm -a H3K4me3_dripc_original.tsv -b H3K4me3_dripc_shuffled.tsv
	$0 -r NT2.rpkm  -a MCF_groseq_antisense_orig.tsv -b MCF_groseq_antisense_shuf.tsv
";

	my $rnaWarning = "
RNA seq file format:
<string name1>	<float value>
<string name2>	<float value>

E.g. 
ENST00000001	259.9
ENST00000002	500

*Your string name has to be identical as the names in -a or -b names
**Any gene name in -a or -b files not found in the RNAseq rpkm file will be assigned 0
";

	my $fileWarning = "
-a and -b file format:
<string nameA>	<float valueA1>	<float valueA2>	<float valueA3> ....
<string nameB>	<float valueB1>	<float valueB2>	<float valueB3> ....

E.g.
ENST000000001

*NAs will be treated as 0
**If number of values are not the same at each row R will be angry

";
	if (not defined($opt_r) or not defined($opt_a) or not defined($opt_b)) {
		print "$usage\n";
		print GREEN "$rnaWarning";
		print YELLOW "$fileWarning";
		die "\n";
	}
	else {
		print RED "\#################################\nSanity check success!!\n";
	}
}

__END__

		#print $outzero1  "$line\n" if $rna == 0;
		#print $outlow1   "$line\n" if $rna > 10 and $rna <= 50;
		#print $outmed1   "$line\n" if $rna > 50 and $rna <= 100;
		#print $outhigh1  "$line\n" if $rna > 100 and $rna <= 200;
		#print $outsuper1 "$line\n" if $rna > 200;


./0_GetTSVFromBED.pl -r ../../../data/NT2.rpkm -i ../../1_Shuffle/Result_125/dripc_promoter.shuffled -a MCF_groseq_promoter_orig.tsv -b MCF_groseq_promoter_shuf.tsv
./0_GetTSVFromBED.pl -r ../../../data/NT2.rpkm -i ../../1_Shuffle/Result_125/dripc_terminal.shuffled -a MCF_groseq_terminal_orig.tsv -b MCF_groseq_terminal_shuf.tsv
./0_GetTSVFromBED.pl -r ../../../data/NT2.rpkm -i ../../1_Shuffle/Result_125/dripc_genebody.shuffled -a MCF_groseq_genebody_orig.tsv -b MCF_groseq_genebody_shuf.tsv
./0_GetTSVFromBED.pl -r ../../../data/NT2.rpkm -i ../../1_Shuffle/Result_125/dripc_antisense.shuffled -a MCF_groseq_antisense_orig.tsv -b MCF_groseq_antisense_shuf.tsv

