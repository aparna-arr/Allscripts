#!/usr/bin/perl

use strict; use warnings;

my ($desired, $try, $pop_size) = @ARGV;
my $original_pop_size = $pop_size;
die "usage: <desired string> <generation> <pop size>\n" unless @ARGV == 3;

my @alp = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "'",",","-","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"," ", "-", "+", ".",")","(","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","!","_");

my $max_score = length($desired);
my $genome = gen_random(length($desired));
my $score1;
($genome, $score1) = score_and_sort($genome);
my ($mutrate, $score2) = (0.05, 0);

for (my $i = 0; $i < $try; $i++) {
	$genome = breed($genome);
	($genome, $score2) = score_and_sort($genome);
	#$mutrate = $score1 eq $score2 ? $mutrate*1.0002 : 0.1;
	#$pop_size = $score1 eq $score2 ? 1.1*$pop_size : $original_pop_size;
	#$mutrate = $mutrate > 1 ? 1 : $mutrate;
	$genome = mutate($genome, $mutrate);
	($genome, $score2) = score_and_sort($genome);
	$score1 = $score2;
	last if $score1 == $max_score;
}


###########
###########
###########

sub gen_random {
	my ($length) = @_;
	my %genome;
	for (my $i = 0; $i < $pop_size; $i++) {
		for (my $j = 0; $j < $length; $j++) {
			$genome{$i}{gen} .= $alp[rand(@alp)];
		}
	}
	return(\%genome);
}

sub breed {
	my %genome = %{$_[0]};
	foreach my $num (keys %genome) {
		if ($num > $pop_size * 0.1) {
			$genome{$num}{gen} = ();
			for (my $i = 0; $i < length($desired); $i++) {
				my $random_parent = int(rand(0.1*$pop_size));
				$random_parent = substr($genome{$random_parent}{gen}, $i, 1);
				$genome{$num}{gen} .= $random_parent;
			}
		}
	}
	return($genome);
}

sub mutate {
	my %genome = %{$_[0]};
	my ($mutrate) = ($_[1]);
	foreach my $num (keys %genome) {
		if ($num > $pop_size * 0.15) {
			my @genome = split("", $genome{$num}{gen});
			for (my $i = 0; $i < @genome; $i++) {
				$genome[$i] = $alp[int(rand(@alp))] if (rand() < $mutrate);
			}
			$genome{$num}{gen} = join("", @genome);
		}
	}
	return(\%genome);
}
sub score_and_sort {
	my %genome = %{$_[0]};
	foreach my $num (keys %genome) {
		my $genome = $genome{$num}{gen};
		$genome{$num}{score} = 0;
		for (my $i = 0; $i < length($desired); $i++) {
			my $gene = substr($genome, $i, 1);
			my $comp = substr($desired, $i, 1);
			$genome{$num}{score} ++ if $gene eq $comp;
		}
	}
	# Sort genome by score
	my $number = 0;
	my %temp;
	my $score2;
	foreach my $num (sort {$genome{$b}{score} <=> $genome{$a}{score}} keys %genome) {
		print "$genome{$num}{gen}\t$genome{$num}{score}\n" if $number == 0;#$number <= 0.1*$pop_size;
		$temp{$number}{gen} = $genome{$num}{gen};
		$temp{$number}{score} = $genome{$num}{score};
		$score2 = $genome{$num}{score} if $number == 0;
		$number++;
	}
	return(\%temp, $score2);
}
