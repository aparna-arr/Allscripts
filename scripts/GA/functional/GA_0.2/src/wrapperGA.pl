#!/usr/bin/env perl
use warnings;
use strict;
use GA;
my @dependencies = ("make_cache.pl", "eval script", "0.2_functional GA script", "HMM_Counter.pl", "wig2fa.pl", "FastaFromBed", "HMM template script", "Normalization method");

# 2 modes : Preprocess and GA. Preprocess prompts to normalize, create various .customfa's, and instructs steps to get emissions for initial HMM.
#
# GA will handle everything when it is actually intended to run GA
#
# Preprocess: Have emissions for initial HMM completely figured out
# -> Normalization done!
# -> should have created all .fasta and wig files
#
# Input: Define regions
# -> check that model and test region do not overlap
# -> check that all regions are on 1 chr
#
# Prompt: Generate HMM Template
# -> save a template file
# -> option to load already-created template
# -> prompt for count files in a certain order, input into template file to make an initial HMM file
#
# Given regions and chromosome .fasta
# Make the cache and test wig files, pipe sig_regions / unsig_regions to eval script
# possibly make run-region?
#
# GA modes: State-specific conditionals in mutate(), normal everything can be mutated.
# -> also debug mode, verbose, quiet 
#
# Final output: HMM model file to be used with genome .customfa (wig2fa.pl again) and stochhmm alone
#

main();
sub main {
  while(1) { 
    print "
GA-StochHMM Wrapper

0) Quit
1) Preprocess Mode
2) Run GA Mode
> ";
    my $choice = <>;
    chomp $choice;

    if ($choice == 0) {
      die "Exiting!\n";
    } 
    elsif ($choice == 1) {
      preprocess();
    }
    elsif ($choice == 2) {
      ga_run();
    }
    else {
      die "Invalid option!\n";
    } 
  }
}

sub preprocess {
while (1) {
    print "
Preprocess Mode
0) Quit to menu
1) Normalize / Load wig file
2) Load regions
3) Create .customfa files
4) Create / Load Template HMM file
5) Input regions for initial HMM emissions
6) Create / Load initial model
7) Continue to Run GA Mode
> ";

    my $choice = <>;
    chomp $choice;

    if ($choice == 0) {
      return;
    }
    elsif ($choice == 1) {
      GA::normalize();
    } 
    elsif ($choice == 2) {
      GA::load_regions();
    }
    elsif ($choice == 3) {
      GA::customfa();
    } 
    elsif ($choice == 4) {
      GA::set_template();
    }
    elsif ($choice == 5) {
      GA::emissions();
    }
    elsif ($choice == 6) {
      GA::set_model();
    }
    elsif ($choice == 7) {
      ga_run();
    }
    else {
      print "Invalid option! Returning to menu\n";
      return;
    }
  }
}

sub ga_run {
  while(1) {
    print "
Run GA Mode
0) Quit to menu
1) Initialize cache and evaluation script
2) Supply parameters for GA
> ";
  
    my $choice = <>;
    chomp $choice;

    if ($choice == 0) {
      main();
    }
    elsif ($choice == 1) {
      GA::initialize();
    }
    elsif($choice == 2) {
      GA::params();
    }
    else {
      print "Invalid option! Returning to menu\n";
      return;
    }
  }
}
