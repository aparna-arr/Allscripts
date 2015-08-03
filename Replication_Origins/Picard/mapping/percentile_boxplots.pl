#!/usr/bin/env perl
use warnings;
use strict;

my $warning = "
Warnings:
Expects SORTED bed file
";

my ($peakfile, $wigfile, $workdir, $dir, $rvar) = @ARGV;
die "usage: $0 <peak file> <full path to wig file> <new working dir/> <tmp dir/> <r var name>$warning\n" unless @ARGV;

`mkdir $workdir`;
my %peaks;
my $prev_chr = "INIT";
open (IN, "<", $peakfile) or die "Could not open $peakfile\n";

print "Starting read-in\n";

while (<IN>) {
  my $line = $_;  
  chomp $line;
  
  if ($line =~ /^#/ || $line =~ /^track/) {
    next;
  }
#  print "$line\n"; 
  my ($chr, $start, $end, $trash) = split(/\s+/, $line) ;#=~ /^(.+)\t(\d+)\t(\d+)\t.+/;
#  print "[$chr] [$start] [$end]\n";
  if ($chr ne $prev_chr && $prev_chr ne "INIT") {
    my $index = @{$peaks{$prev_chr}} - 1;
    if ($peaks{$prev_chr}[$index-1]{end} >= $peaks{$prev_chr}[$index]{start} - $peaks{$prev_chr}[$index]{len}*5 ) {
      pop(@{$peaks{$prev_chr}});
    }
  }

  my $flag = 0;
  if (exists($peaks{$chr})) {
    my $num = @{$peaks{$chr}} - 1;
    if (@{$peaks{$chr}} > 1) {
      if ($peaks{$chr}[$num-1]{end} >= $peaks{$chr}[$num]{start} - $peaks{$chr}[$num]{len}*5 ) {
        $flag++;
      }
    } 
    
    if ($start <= $peaks{$chr}[$num]{end} + $peaks{$chr}[$num]{len}*5) {
      $flag++;
    } 
  }
  
  if ($flag) {
    pop(@{$peaks{$chr}});
  }
#  print "[$chr] [$start] [$end]\n";
  push(@{$peaks{$chr}}, {start => $start, end => $end, len => int(($end - $start)*.1) + 1});
  $prev_chr = $chr;
}

close IN;

print "Done read in.\n";

my @files; 

chdir($workdir) ;
`mkdir $dir`;

foreach my $chrom (sort keys %peaks) {
  print "Splitting chr $chrom\n";
  for(my $i = 0; $i < @{$peaks{$chrom}}; $i++) {
    my $binstart = $peaks{$chrom}[$i]{start};
    my $loop = 0;
#    print "[$peaks{$chrom}[$i]{start}] [$peaks{$chrom}[$i]{end}] [$peaks{$chrom}[$i]{len}] [$binstart]\n";
    while ($loop < 10) {
#      print "binstart is $binstart end is $peaks{$chrom}[$i]{end}\n";
      my $line = "$chrom\t$binstart\t" . ($binstart + $peaks{$chrom}[$i]{len}) ;
      open(TMP, ">>", "$dir$loop.txt");
      print TMP "$line\n";
      close TMP;
#      `echo $line >> $dir$loop.txt`;
      if (@files < 20) {
        push(@files, "$dir$loop.txt");
      }
      $loop++;
      $binstart+=$peaks{$chrom}[$i]{len};
    }

    for (my $n = 0; $n < 5; $n++) {
      open(TMP, ">>", $dir . "before_$n.txt");
      print TMP "$chrom\t" . ($peaks{$chrom}[$i]{start} - $peaks{$chrom}[$i]{len}*($n+1)) . "\t" . ($peaks{$chrom}[$i]{start} - $peaks{$chrom}[$i]{len}*$n) . "\n";
      close TMP;
      if (@files < 20) {
        push(@files, $dir . "before_$n.txt");
      }
    }

    for (my $m = 0; $m < 5; $m++) {
      open(TMP, ">>", $dir . "after_$m.txt");
      print TMP "$chrom\t" . ($binstart + $peaks{$chrom}[$i]{len}*$m)  . "\t" . ($binstart + $peaks{$chrom}[$i]{len}*($m + 1)) . "\n";  
      close TMP;
      if (@files < 20) {
        push(@files, $dir . "after_$m.txt");
      }
    }
  }
}

print "Done splitting, starting map\n";

my ($wigname) = $wigfile =~ /^.+\/{0,1}(.+)\.wig$/;
my @outfiles;
print "Size of files is ". @files . "\n";
for (my $k = 0; $k < @files; $k++) {
  print "Mapping $files[$k]\n";
  my $output = `perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed.pl -m -w $wigfile -v -r /data/aparna/cache $files[$k]`;
  print "Done mapping $files[$k]\n";
  my ($filename) = $files[$k] =~ /\/{0,1}(.+)$/;
  push (@outfiles, "$wigname\_$filename");
} 

# Plot
open (R, ">", "R_script.R");

print R "library(reshape)\nlibrary(ggplot2)\n";

for (my $l = 0; $l < @outfiles; $l++) {
  print R "$rvar\_$l<-read.delim(\"$outfiles[$l]\", header=F)\n";
}  

print R "l<-list(";

for (my $o = 4; $o >= 0; $o--) {
 print R "data.frame(before_$o=log10($rvar\_" . (10 + $o)  . "\$V4), group=\"$rvar\"), ";
}  

for (my $p = 0; $p < 10; $p++) {
  print R "data.frame(per_$p=log10($rvar\_$p\$V4), group=\"$rvar\"), ";
}

for (my $q = 0; $q < 5; $q++) {
 print R "data.frame(after_$q=log10($rvar\_" . (15 + $q)  . "\$V4), group=\"$rvar\"), ";
}  

print R ")\n";

print R "l<-melt(l)\n";

print R "plot<-ggplot(l, aes(variable,value)) +
geom_boxplot(aes(fill=group))
plot
";

close R;
