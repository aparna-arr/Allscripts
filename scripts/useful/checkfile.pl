#!/usr/bin/env perl
use warnings;
use strict;

my (@files) = @ARGV;
die "usage: <list of files to check> <internal to check>\n" unless @ARGV > 1;

while(1) {
	my $start = time;
	for (my $j = 0; $j < @files - 1; $j++) {
		my $file = -s $files[$j];
		if ($file < 1024) {
			$file .= " B";
		}
		elsif ($file < 1024*1024) {
			$file = int(($file*10/1024))/10 . " M";
		}
		elsif ($file < 1024 * 1024 * 1024) {
    {
			$file = int(($file*10 / (1024*1024) ))/10 . " G";
		}		

		print "$file | $files[$j]\n";
	}
	print "\n";

	if ((my $rem = $files[@files-1] - (time - $start)) > 0) {
		sleep $rem;
	}	
}


