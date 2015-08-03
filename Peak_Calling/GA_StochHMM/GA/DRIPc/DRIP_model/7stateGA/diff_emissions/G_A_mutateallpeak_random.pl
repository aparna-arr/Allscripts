#!/usr/bin/perl -w
# By Paul Lott for SkewR
# Modified by Stella for CpG Island
#####################################

use strict; use warnings;
#use G_A;
#use G_A_7states;
use G_A_mutateallpeak;
use FAlite;
use vars qw($KILLED_POP $HIGHEST_FP $SEQFILE $HMM_MODEL $OUTPUT_DIR $REPETITIONS $POPULATION_SIZE $THRESHOLD $THREAD_NUM $SAVED_POP $MUTATION_RATE $MAX_MUTATION_CHANGE $CROSSOVER_RATE $PARENT_SIZE);

($SEQFILE, $HMM_MODEL, $OUTPUT_DIR, $REPETITIONS, $POPULATION_SIZE, $THRESHOLD, $THREAD_NUM, $SAVED_POP) = @ARGV;

my $usage = "Usage: $0 <Fasta> <HMM_model> <Output dir> <Generations> <Population Size> <Threshold> <Input Population>\n\
[Fasta file]		: Fasta file (1+ fasta). !!Make sure to put not case sens 'CGINMI' for CGI/NMI seqs and 'NONCGI' for non CGI seqs somewhere in header)
[HMM_Model] 		: Model of HMM (must be StochHMM 0.221)
[Output Directory] 	: Directory for Output (Whatever)
[Generation] 		: Number of generation that you want to run the Genetic Algorithmn
[Population Size] 	: Number of hmm model you want to generate
[Threshold] 		: Posterior probability threshold [0.9]
[Thread number]		: Number of threads you want to use
[Saved Population]	: Saved Population from previous run (Random_*.ga)

Result HMM file is at Output Directory. Each HMM file number is ordered by its accuracy score, from best to worst.
E.g. [Output Directory]\/0.hmm is always the best

";

die $usage unless @ARGV >= 7;
die "$usage\nThread number must be bigger than 0\n" unless $THREAD_NUM > 0;
# Command line argument

print "Round 0: Initialization\n";
# Check for existence of necessary script/file in output directory
# If not present (or directory not present) then create/copy as necessary
check_file_presence(); # NOTE can ignore

# Define the GA parameter
#$MUTATION_RATE=0.075;  #How often do mutations occur 
#$MAX_MUTATION_CHANGE=0.2;  #By how much do we want Mutation to be able to vary then values by 
#$MUTATION_RATE=0.2;  
#$MAX_MUTATION_CHANGE=0.4;  
$MUTATION_RATE=0.1;  
$MAX_MUTATION_CHANGE=0.2;  
#$MUTATION_RATE=0.4; 
#$MAX_MUTATION_CHANGE=0.6;  
$CROSSOVER_RATE=0.05;	#Frequency of crossover # NOTE is this necessary
$PARENT_SIZE = 0.2;  # NOTE takes top 20% ??
$KILLED_POP = 0; # NOTE pop size remains constant
# Population input. Either creating new or using saved population
my $population;
if (not defined($SAVED_POP)) {
	#To start the GA fresh and generate a new population
	print "\tCreating new population of $POPULATION_SIZE\n";
  # This takes in number of individuals to create, a distribution,creates $POP_SIZE individuals, mutates the same dist for each, stores each individual, and returns the new population
	$population=Population->new_random(); 
  # NOTE Package Population
	print "\tEvaluating population\n";
	$population->evaluate();
	print "\tStoring new population\n";
	$population->store(skew_filename());
}

else {
	# If re-starting Genetic Algorithm from existing data, we need to retreive the old data
	$population=Storable::retrieve("$SAVED_POP");
	$population -> evaluate();
}

my ($max, $max_indiv) = $population->max();  #Max fitness found in the population
my $reps=0;  #Which generation is currently being evaluated

print "Round 0 result:\tMax Pop: $max\tMax Individual: $max_indiv\n";
print "Done initialization, now performing Genetic Algorithm for $REPETITIONS generation\n\n";

# Next, Loop to perform purging of the low fitness individuals, mating of high fitness individuals
# and evaluation.
# Each generation is stored so that you can got back to the previous generations
while($reps<$REPETITIONS){
    	$reps++;  #Increase number of generations
	print "Round:\t$reps\n";

    	$population->purge();	#Cull the rejects from the population
    	$population->mate();	#Mate the remaining population
    	$population->evaluate();  #Calculate the Fitness of the individuals
    	$population->store(skew_filename()); # Save the data
    
    	my ($new_max_pop, $new_max_indiv) = $population->max();
    
	if ($new_max_indiv > $max){
        	$max= $new_max_indiv;
    	}
    
	print "Round $reps result:\tMax Pop: $new_max_pop\tMax Individual: $new_max_indiv\n\n"; #Report progress 
}


###############
# SUBROUTINES #
###############

#Generate a filename for GA data file based on the time
sub skew_filename{
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $filename="$OUTPUT_DIR\/STORED_POP\/Random_GA_data_";
	$year+=1900;
	$mon+=1;
	my $tail=sprintf("%02d_%02d_%4d_%02d_%02d",$mon,$mday,$year,$hour,$min);
	
	$filename.= $tail . ".ga";
	
	return $filename;
}


sub check_file_presence {
	if (not -d($OUTPUT_DIR)) {
		mkdir($OUTPUT_DIR);
	}
	if (not -d "$OUTPUT_DIR\/STORED_POP") {
		mkdir "$OUTPUT_DIR\/STORED_POP";
	}
	if (not -e ("$OUTPUT_DIR\/$SEQFILE")) {
		system("cp $SEQFILE $OUTPUT_DIR\/$SEQFILE");
	}
	#if (not -e ("$OUTPUT_DIR\/StochHMM")) {
#		system("cp bin\/StochHMM $OUTPUT_DIR\/StochHMM");
	#}
	#if (not -e ("$OUTPUT_DIR\/evaluate_report.pl")) {
#		system("cp bin\/evaluate_report.pl $OUTPUT_DIR\/evaluate_report.pl");
#		system("cp faster_eval_peaks.pl $OUTPUT_DIR\/faster_eval_peaks.pl");
	#}
}

sub split_fasta {
	my ($input, $output_dir) = @_;
	my @files;
	open (my $in, "<", "$output_dir\/$input") or die "Cannot read from $output_dir\/$input: $!\n";
	my $fasta = new FAlite($in);
	while (my $entry = $fasta->nextEntry()) {
	        my ($def, $seq) = ($entry->def, $entry->seq);
	        $def =~ s/ /_/g;
	        $def =~ s/>//;
	        $def =~ s/\'//g;
	        open (my $out, ">", "$output_dir\/$input\_$def\.fa") or die "Cannot write to $def: $!\n";
		push(@files, "$input\_$def\.fa");
	        print $out ">$def\n$seq";
	        close $out;
	}
	close $in;
	return(\@files);
}

__END__

TODO: Automate R script to create graph?
