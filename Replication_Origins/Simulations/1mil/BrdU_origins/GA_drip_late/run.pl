#!/usr/bin/perl

use strict; use warnings;
use Thread;
use Thread::Queue;

my ($origin, $intersect, $outfile) = @ARGV;
die "usage: <\"eary\"||\"late\"> <full path to file to intersect with origin> <outfile name>\n" unless @ARGV;

my $Q = new Thread::Queue;
for (my $i = 0; $i < 1000000; $i++) {

#	my $cmd = "bedtools shuffle -chrom -excl ../../gaps_hg19.bed -i ../common_late_origins_ENCODE.bed -g ../hg19.genome > temp_$i ; bedtools intersect -wo -a temp_$i -b ../../../../region_metaplots/cpg_islands_all_parsed.bed | awk '{print \$7}' | awk '{sum+=\$1} END {print sum}' >> 1mil_simulation_cpg_late.txt ; rm temp_$i";
	my $cmd = "bedtools shuffle -chrom -excl ../../../gaps_hg19.bed -i ../../common_$origin\_origins_ENCODE.bed -g ../../hg19.genome > temp_$i ; bedtools intersect -wo -a temp_$i -b $intersect | awk '{print \$7}' | awk '{sum+=\$1} END {print sum}' >> $outfile ; rm temp_$i";
	$Q->enqueue($cmd);
}
$Q->end;

my @threads;
for (my $i = 0; $i < 8; $i++) {
	$threads[$i] = threads->create(\&worker, $i, $Q);
}

for (my $i = 0; $i < 8; $i++) {
	$threads[$i]->join();
}

sub worker {
	my ($thread, $queue) = @_;
	my $thread_id = threads->tid;
	
	while ($queue->pending) {
		my $command = $queue->dequeue;
		system($command);
		#print "$thread_id: RUNNING $command\n";
	}
	return;
}
