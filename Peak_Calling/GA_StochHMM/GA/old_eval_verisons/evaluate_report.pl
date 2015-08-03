#!/usr/bin/perl
# Evaluation file for GA_StochHMM
# -posterior only
# By Paul and modified by Stella
#####################################

use strict; use warnings;

my ($input, $threshold) = @ARGV;
die "usage: $0 <result> <threshold>\n" unless @ARGV == 2;
my ($name) = $input =~ /^(\d+)\.report/;
#my $class = define_class($input);
open (my $in, "<", $input) or die "Cannot read from $input: $!\n";
my %result;
my $class;
my ($tp, $tn, $fp, $fn) = (0,0,0,0);
my $count = 0;
my ($totalline) = `wc -l $input` =~ /(^\d+)/;
my $total = 0;
while (my $line = <$in>) {
	chomp($line);
	if ($line =~ /^Sequence/) {
		$result{class} = define_class($line);
		#print "$line\n$result{class}\n";
	}
	elsif ($line =~ /^Position/) {
		$result{position} = $line;
	}
	elsif ($line =~ /^\d+/) {
		push(@{$result{number}}, $line);
		$total++;
	}
	elsif (defined $result{class} and $line =~ /^Posterior/) {
		my @arr = evaluate_report(\%result);
		$tp += $arr[0];
		$tn += $arr[1];
		$fp += $arr[2];
		$fn += $arr[3];
		%result=();
	}
	$count++;
	#printf STDERR "LINE ON $input\t%.2f %%\r", 100 * $count / $totalline;
}

if (defined $result{class}) {
	my @arr = evaluate_report(\%result);
	$tp += $arr[0];
	$tn += $arr[1];
	$fp += $arr[2];
	$fn += $arr[3];
	%result=();
}
print "$name,$tp,$tn,$fp,$fn";
close $in;

###############
# SUBROUTINES #
###############

sub define_class {
	my ($input) = @_;
	#print "INPUT $input\n";
	return("cgi") if ($input =~ /CGINMI/i);
	return("noncgi") if ($input =~ /NONNMI/i);
	return("genome") if ($input =~ /GENOME/i);
	die "Name must contain either CGINMI or NONCGI or GENOME\n";
}

sub evaluate_report{
        my ($report)=@_;
	my %report = %{$report};
	my $class = $report{class};

	# Get the column position of each state type in the table
        my %pos; # Position of state in probabilities table
	my ($pos, @type) = split("\t", $report{position});
        for (my $i = 0; $i < @type; $i++) {
            	$pos{type}[$i] = $type[$i];
        }

        my %res; # resing output
        my ($below_threshold, $curr_start, $curr_type) = (0, 1, "START");
	for (my $i = 0; $i < @{$report{number}}; $i++) {
		my $line = $report{number}[$i];
		
		# Get state type for each row (G/C/both below threshold)
                my ($pos, @prob) = split("\t", $line);
		my $check = 0;
              	for (my $j = 0; $j < @prob; $j++) {
         	        if ($prob[$j] >= $threshold) { #assume that threshold is more than 1/# of state
                	        my $type = $pos{type}[$j];
                                
				# New
                                if (keys %{$res{$type}} == 0) {
                        		$res{$type}{$pos}{end} = $pos;
                                        $curr_type = $type;
                                        $curr_start = $pos;
#					print STDERR "$i\t$type\n";
                               	}
                                # Adjacent type
                                elsif ($curr_type eq $type and $res{$type}{$curr_start}{end} == $pos - 1) {
                                	$res{$type}{$curr_start}{end} = $pos;
#					print STDERR "$i\t$type\n";
                               	}
                                # New with same type
                                elsif ($curr_type eq $type and $res{$type}{$curr_start}{end} != $pos - 1) {
                                	$res{$type}{$pos}{end} = $pos;
                                        $curr_start = $pos;
#					print STDERR "$i\t$type\n";
                                }
				#New with different type
                                elsif ($curr_type ne $type) {
                                	$res{$type}{$pos}{end} = $pos;
                                        $curr_type = $type;
                                        $curr_start = $pos;
#					print STDERR "$i\t$type\n";
                                }
				else {die}
                        }
			else {
				$check++;
			}
                }

              	$below_threshold++ if $check == @prob;
#		print STDERR "$i\tNOTHING\n" if $check == @prob;
        }
        return(compare_bp2bp(\%res, $class, $below_threshold));
}

sub compare_bp2bp {
       my %data;
        my ($res, $class, $below_threshold) = @_;
        my %res = %{$res};

        my ($tp, $tn, $fp, $fn) = (0,0,0,0);

        my %total;
        # compare with any cgi bed file
        foreach my $type (keys %res) {
                foreach my $start (sort {$a <=> $b} keys %{$res{$type}}) {
                        my $end = $res{$type}{$start}{end};
			my $sum = $end - $start + 1;
#			print STDERR "$start - $end\t$type\n";

			if ($type eq "C") {
				if ($class eq "cgi") {
					$tp += $sum;
				}
				else {
					$fp += $sum;
				}
			}
			else {
				if ($class eq "cgi") {
					$fn += $sum;
				}
				else {
					$tn += $sum;
				}
			}
		}
	}
#	print STDERR "$below_threshold\tNOTHING\n";

	if ($class eq "cgi") {
		$fn += $below_threshold;
	}
	else {
		$tn += $below_threshold;
	}
	return($tp,$tn,$fp,$fn);
}

__END__
#my $sen = ($tp + $fp) == 0 ? 0 : $tp / ($tp + $fn);
#my $spe = ($tp + $tn) == 0 ? 0 : $fp / ($fp + $tn);
#my $pre = ($tp + $fp) == 0 ? 0 : $tp / ($tp + $fp);
#my $rec = ($tp + $fn) == 0 ? 0 : $tp / ($tp + $fn);
#my $acc = ($tp + $tn + $fp + $fn) == 0 ? 0 : ($tp + $tn) / ($tp + $tn + $fp + $fn);
#my $f = ($pre + $rec) == 0 ? 0 : (2 * $pre * $rec) / ($pre + $rec);

