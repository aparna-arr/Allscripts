#!/usr/bin/env perl
use warnings ;
use strict ;
use Cache::FileCache;
use File::Basename;
# for use with GA stochhmm
# sets cache for the eval_script.pl script
# wig file MUST BE SORTED and MUST have constant span

my $THRESHOLD = 10; # If value is below this threshold, base pairs are declared "not significant" : very unlikely to be a peak. If values are above 2*$THRESHOLD, base pairs are declared "significant" : could be in a peak

my ($cache_root, $wigfile) = @ARGV;
die "usage: $0 <cache> <wig>\n" unless @ARGV;

#my $name = $wigfile =~ /\/{0,1}(.+)$/; # FIXME check regex
my $name = basename($wigfile, ".wig");

$name.=".wig";

my $abs_path = `cd $cache_root ; pwd`; 
chomp $abs_path;
$abs_path .= "/"; # because relative path crashes
#print STDERR "abs_path is [$abs_path]\n";

my $cache = new Cache::FileCache();
$cache -> set_cache_root($abs_path);

my $sig_blocks;
my $unsig_blocks;

open (IN, "<", $wigfile) or die "Could not open $wigfile\n";
my $chr = "INIT";
my $curr_chr = "INIT";
my $span;
my @wig;

while (<IN>) {
  my $line = $_ ;
  chomp $line ;

  if ($line !~ /^\d/) {
    next if $line  !~ /chrom=/;
    ($chr, $span) = $line =~ /chrom=chr(.+) span=(\d+)/i;
    ($chr) = $line =~ /chrom=chr(.+)/i if not defined($chr);
    $span = 1 if not defined($span) or $span == 0;
  if ($chr ne $curr_chr and $curr_chr ne "INIT") {
    print STDERR "setting $curr_chr cache at $name\.$curr_chr\.cache\n";
    $cache -> set("$name\.$curr_chr\.cache", \@wig);
    @wig = ();
  }
    $curr_chr = $chr;
  }
  else {
    my ($pos, $val)   = split("\t", $line)    ;
    if ($val > 10) {
      push (@wig, {start => $pos, value=>$val});
      if ($val > 2 * $THRESHOLD) { # NOTE threshold
        $sig_blocks++;
      }
    }
    elsif ($val < $THRESHOLD) {
      $unsig_blocks++;
    }
  }
}
close IN;
print STDERR "setting $curr_chr ($chr) cache at $name\.$curr_chr\.cache\n";
$cache -> set("$name\.$curr_chr\.cache", \@wig);

print "$sig_blocks\t$unsig_blocks\n";  
