#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;
use Cache::FileCache;


my $cache = new Cache::FileCache();
my $cache_root = '/data/aparna/cache/';
$cache -> set_cache_root($cache_root);

my ($file) = @ARGV;
die "usage: $0 <wig>\n" unless @ARGV;

my $name = basename($file, ".wig");

open (IN, "<", $file) or die "could not open file\n";

print "Making tmp files\n";

my $chrom = "INIT";
my @array;

while (<IN>) {
  my $line = $_;
  
  if ($line !~ /^variableStep/ && $line !~ /^\d+/) {
    next;
  }

  if ($line =~ /^variableStep/) {
    if ($chrom ne "INIT") {
      close OUT;
    }

    ($chrom) = $line =~ /chrom=(\S+)\s+/;
    print "chrom is $chrom\n";

    open (OUT, ">>", "$chrom.tmp");
    print OUT $line;
    $array[@array] = "$chrom.tmp";
  }
  else {
    print OUT $line;
  }
}

close OUT;
close IN;

print "Done making tmp files\n";


print "Starting putting in cache\n";
for (my $i = 0; $i < @array; $i++) {
  print "tmp file $array[$i]\n";
  open (TMP, "<", $array[$i]) or die "Could not open temp file $array[$i]\n";

  my ($chr) = $array[$i] =~ /^(.+)\.tmp$/;
  my $span = 0;
  my @tmp;


  while (<TMP>) {
    my $line = $_;
    chomp $line;
  
    if ($line =~ /^variableStep/) {
      ($span) = $line =~ /span=(\d+)/;
    }
    else {
      my ($pos, $val) = $line =~ /(\d+)\t(\S+)/;
      push (@tmp, {start => $pos, end => $pos + $span, value => $val})
    }
  }
  
  $cache -> set("$name\.$chr.cache", \@tmp);
#  print "$name\.$chr\.cache\n";
  close TMP;
  @tmp = ();
}
`rm *.tmp`;
print "Done putting in cache\n";
