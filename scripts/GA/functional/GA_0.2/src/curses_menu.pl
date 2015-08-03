#!/usr/bin/env perl
use warnings;
use strict;
use Curses;
initscr();

my ($a, $b, $c);
$a = $b = $c = 0;
my $table = settable();

addstring(0,0, $table);
refresh();
my $clear = " "x100;

addstring (7,0, "ERRORS");
my $error_count = 8;
while(1) {

	clearall();

	addstring(5,0,"Enter a value (q to quit): ");
	refresh();

	my $in = getstring();

	if ($in eq 'q') {
		last;
	}

	addstring(6, 0, "Which var? (a, b, or c): ");
	
	my $var = getstring();

	if ($var eq 'a') {
		$a = $in;
	}
	elsif ($var eq 'b') {
		$b = $in;	
	}
	elsif ($var eq 'c') {
		$c = $in;
	}
	else {
		addstring($error_count,0, "Bad Var!");
		$error_count++;
		refresh();
		next;
	}

	$table = settable();
	addstring(0,0, $table);

	refresh();
}

endwin();


sub settable {
	return (
"|$a	|$b	|$c"
);
}

sub clearall {
	addstring(0,0,$clear)
	addstring(5,0,$clear);
	addstring(6,0,$clear);
}
