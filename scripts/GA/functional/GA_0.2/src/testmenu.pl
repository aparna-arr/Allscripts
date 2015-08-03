#!/usr/bin/env perl
use warnings;
use strict;
use Curses;
# testing simplified terminal application


	system('clear');

	my ($a, $b, $c);
	$a = $b = $c = 0;
	my $val;
	setval();
	print $val;

	while (1) {
		print "\n\nExit?> ";	
		my $exit = <>;
		chomp $exit;
		if ($exit =~ /y/i) {
			last;
		}

		print "Enter a value> ";
		my $user = <>;
		chomp $user;
		print "Which letter would you like to set?> ";
		my $var = <>;	
		chomp $var;	
		
		if ($var eq 'a') {
			$a = $user;
		}
		elsif ($var eq 'b') {
			$b = $user;
		}
		elsif ($var eq 'c') {
			$c = $user;
		}
		else {
			print "That is not one of the vars! Try again\n";
			next;
		}
		system('clear');
		setval();	
		print $val;
	}
sub setval {
	$val = "
|$a	|$b	|$c	|
";
}	
