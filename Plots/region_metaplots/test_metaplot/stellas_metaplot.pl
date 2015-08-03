#!/usr/bin/perl
# metaplot.pl
# This script takes wig file and multiple bed 6 files (strand info inside)
# get value for each coordinate from bed file from wig file,
# creates metaplot of average value,
# and produces two column coordinate and value file
# by stella
######################

use strict; use warnings;
use Cache::FileCache;

my ($wigfile, $MAXWINDOW, @bedfile) = @ARGV;
die "usage: $0 <wigfile> <MAXWINDOW> <bed1> <bed2> <bed3> <etc...>\n" unless @ARGV >= 2;

print "Aparna: Ignore line 200ish warning\n";
my %wig;
# Caching allows you to skip parsing wigfile
# Stores the pre-parsed wig hash into cache
# Next time you need to use it, you can 
# just invoke the hash from cache (faster than loading it again)
# Below is the code, which is commented out because 
# we are not using it right now
# CODE:

# my $cache = new Cache::FileCache();
# $cache -> set_cache_root("/home/mitochi/Desktop/Cache");
# my $wig = $cache -> get("$wigfile");
# if (not defined($wig)) {
print "\nProcessing $wigfile\n";
%wig = %{process_wig($wigfile)};
# print "Done processing, setting cache\n";
# $cache -> set("$wigfile", \%wig);
# }
# else {
# %wig = %{$wig};
# }

my @output;
foreach my $bedfile (@bedfile) {
	print "Processing $bedfile\n";
	my %bed = %{process_bedfile($bedfile)};
	my $output = process_wig_and_bed(\%wig, \%bed, $bedfile);
	print "Finished processing bedfile $bedfile\n\n";
	push(@output, $output);
}

print "All done! Output tsv files:\n";
for (my $i = 0; $i < @output; $i++) {
	print "$i\t$output[$i]\n";
}
print "\n";

###############
# SUBROUTINES #
###############

# Processing wig file 
# The values and position are stored in %wig in memory
# Position are indexed within its 100000
# E.g. position 1E6 is mapped into 10
# Data structure:
# $wig{$chr}{$index}{$position}{value}
# $wig{$chr}{$index}{$position}{span}

sub process_wig {
	my ($wigfile) = @_;
	my $chr;
	my $curr_chr = "INIT";
	my $SPAN;
	open (my $in, "<", $wigfile) or die;
	while (my $line = <$in>) {
		chomp($line);
		next if $line =~ /\#/;
		next if $line =~ /track/;
		if ($line =~ /variable/) {
			($chr, $SPAN) = $line =~ /chrom=(.+) span=(\d+)/;
			print "Processing chr $chr\n" if $chr ne $curr_chr;
			$curr_chr = $chr;
		}
		else {
			my ($pos, $val) = split("\t", $line);
			die if not defined($val);
			$wig{$chr}{int($pos/100000)}{$pos}{val} = $val;
			$wig{$chr}{int($pos/100000)}{$pos}{span} = $SPAN;
		}
	}
	close $in;
	print "Done processing wigfile $wigfile\n\n";
	return(\%wig);
}

# Processing bedfile
# Bedfile coordinates are stored in %bed
# Similar to wig, each coordinate is indexed 
# Data structure:
# $bed{$chr}{$index_start}{$index_end}{$start}{$end}{strand} = $strand
# PS: This data structure can be optimized to be less confusing but I 
# have not done it at this moment

sub process_bedfile {
	my ($bedfile) = @_;
	my %bed;
	open (my $in, "<", $bedfile) or die;
	while (my $line = <$in>) {
		chomp($line);
		next if $line =~ /track/;
		my ($chr, $start, $end, $name, $dot, $strand) = split("\t", $line);
		my $ID = (keys %bed); #ID increment as bed key increases
		$bed{$ID}{chr} 		= $chr;
		$bed{$ID}{start_index} 	= int($start/100000);
		$bed{$ID}{end_index} 	= int($end/100000);
		$bed{$ID}{start} 	= $start;
		$bed{$ID}{end} 		= $end;
		$bed{$ID}{strand} 	= $strand
	}
	close $in;
	return(\%bed);
}

# Look up value for each coordinate in %bed from %wig.
# Loop over each bedfile
# Then loop over each start_index of that bedfile 
# and search for its corresponding value from wig index
# If not found and/or end_index is different from start_index,
# then loop over each end_index of the bedfile and search in wig index

sub process_wig_and_bed {
	my ($wig, $bed, $bedfile) = @_;
	my %wig = %{$wig};
	my %bed = %{$bed};
	my $chr = "";
	my $max;
	my %total;

	foreach my $ID (sort keys %bed) {
		my $chr 	= $bed{$ID}{chr};
		my $start_index = $bed{$ID}{start_index};
		my $end_index   = $bed{$ID}{end_index};
		my $start 	= $bed{$ID}{start};
		my $end 	= $bed{$ID}{end};
		my $strand 	= $bed{$ID}{strand};
		
		# First, loop over $start_index of %wig
		foreach my $pos (sort {$a <=> $b} keys %{$wig{$chr}{$start_index}}) {
			my $SPAN = $wig{$chr}{$start_index}{$pos}{span};
			next if not defined($SPAN);

			# Loop over the span of that wig location
			# This would screw up if wig span is huge
			# e.g. span = 1 million, but it's normally
			# not more than 100 so it's more efficient to
			# loop over span
			for (my $i = $pos; $i < $pos+$SPAN; $i++) {
				last if $i - $start > $MAXWINDOW and ($strand eq "+");
				last if $end - $i   > $MAXWINDOW and ($strand eq "-");
				if (between($i, $start, $end) == 1) {
					if ($strand eq "+" and defined($wig{$chr}{$start_index}{$i}{val})) {
						$total{total}[$i-$start] += $wig{$chr}{$start_index}{$i}{val};
						$total{count}[$i-$start] ++;
						$max = $i - $start if not defined($max) or $max < $i - $start;
					}
					elsif ($strand eq "-" and defined($wig{$chr}{$start_index}{$i}{val})) {
						$total{total}[$end - $i] += $wig{$chr}{$start_index}{$i}{val};
						$total{count}[$end - $i] ++;
						$max = $end - $i if not defined($max) or $max < $end - $i;
					}
				}
			}
		}
		
		# If end index of the bedfile is not the start index, then the above only process half of the coordinate of the bedfile
		# E.g. if bedfile start at 10,090,000 and end at 10,105,000 index would be 100 and 101. 
		# The above will only get wig value up until 10,099,999 and not 10,100,000-1,105,000
		# Therefore we must loop over wig hash with the corresponding end index
		if ($end_index != $start_index) {
			foreach my $pos (sort {$a <=> $b} keys %{$wig{$chr}{$end_index}}) {
				my $SPAN = $wig{$chr}{$end_index}{$pos}{span};next if not defined($SPAN);
				for (my $i = $pos; $i < $pos+$SPAN; $i++) {
					last if $i - $start > $MAXWINDOW and ($strand eq "+");
					last if $end - $i   > $MAXWINDOW and ($strand eq "-");
					if (between($i, $start, $end) == 1) {
						if ($strand eq "+" and defined ($wig{$chr}{$start_index}{$i}{val})) {
							$total{total}[$i-$start] += $wig{$chr}{$end_index}{$i}{val};
							$total{count}[$i-$start] ++;
							$max = $i - $start if not defined($max) or $max < $i - $start;
						}
						elsif ($strand eq "-" and defined($wig{$chr}{$start_index}{$i}{val})) {
							$total{total}[$end - $i] += $wig{$chr}{$end_index}{$i}{val};
							$total{count}[$end - $i] ++;
							$max = $end - $i if not defined($max) or $max < $end - $i;
						}
					}
				}
			}
		}
	}

	
	# Calculate the average of that position	
	for (my $i = 0; $i < $MAXWINDOW; $i++) {
		next if not defined($total{total}[$i]);
		$total{total}[$i] /= $total{count}[$i];
	}

	# Print out as standard 2 column (position, value)
	my ($bedname) = $bedfile =~ /.+\/(.+)$/;
	$bedname = $bedfile if not defined($bedname);
	my ($wigname) = $wigfile =~ /.+\/(.+)$/;
	$wigname = $wigfile if not defined($wigname);

	my $fail_to_open = 0;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	open (OUT, ">", "$bedname.$wigname.tsv") or $fail_to_open = 1 and print "Cannot write to $bedname.$wigname.tsv:$!\n";
	open (OUT, ">", "$year\_$mon\_$mday\_$hour\_$min\_$sec.tsv") if ($fail_to_open == 1);
	for (my $i = 0; $i < $MAXWINDOW; $i++) {
		if (defined($total{total}[$i])) {
			print OUT "$i\t$total{total}[$i]\n" if defined($total{total}[$i]);
		}
		else {
			print OUT "$i\t0\n";
		}
	}
	close OUT;

	return("$bedfile.$wigfile.tsv") if $fail_to_open == 0;
	return("year\_$mon\_$mday\_$hour\_$min\_$sec.tsv") if $fail_to_open == 1;
}

sub between {
	my ($pos, $start, $end) = @_;
	return 1 if ($pos >= $start and $pos <= $end);
}

__END__

Todo: Make process_wig_and_bed less confusing
