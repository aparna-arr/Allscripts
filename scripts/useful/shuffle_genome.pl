#!/usr/bin/perl
use strict; use warnings;
use Thread;
use Thread::Queue;

my $warning = "
Warnings:
Number of threads hardcoded to 8

";

my ($gap, $genome, $tmp, $loops, $shuffle, @files) = @ARGV;
die "usage: <gap file> <genome file> <temp file dir> <number of shuffles> <file to be shuffled> <files to be intersected> <outfiles>\n$warning" unless @ARGV;

if (@files % 2 != 0) {
  die "Num of files to be intersected and num outfiles must be the same!\n";
}

my $Q = new Thread::Queue;
for (my $i = 0; $i < $loops; $i++) {

	my $cmd = "bedtools shuffle -chrom -excl $gap -i $shuffle -g $genome > $tmp/temp_$i;";

  for (my $j = 0; $j < @files / 2; $j++) { 
    $cmd .= " bedtools intersect -a $tmp/temp_$i -b $files[$j] |  awk '{print \$3 - \$2}' | awk '{sum+=\$1} END {print sum}' >> $files[$j + (@files / 2)];" ; 
  }

  $cmd .= " rm $tmp/temp_$i";

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
