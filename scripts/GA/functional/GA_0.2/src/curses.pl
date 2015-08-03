#!/usr/bin/env perl
use warnings;
use strict;
use Curses;

initscr();
my ($row, $col);

getmaxyx($row, $col);
addstr(0,0,"Test");
refresh();

my $chr = getstring();

addstr(1,0,$chr);
refresh();

sleep 5;

endwin();
