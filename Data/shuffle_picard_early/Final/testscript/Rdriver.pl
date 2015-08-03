#!/usr/bin/env perl
use warnings;
use strict;

my ($dir, $map, $intfile, $cache) = @ARGV;
die "usage: <.shuffled .bed dir/> <file to map> <file to intersect> <cache/>" unless @ARGV;

my @files = <$dir*>;

print "Making u/ v/\n";
`mkdir u; mkdir v`;

my $cmdu = "perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -w $map -r $cache ";
my $cmdv = "perl -I /usr/local/bin/Perl /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -w $map -r $cache ";

print "Looping through files in $dir\n";
for (my $i = 0; $i < @files; $i++) {
  my $prev = $files[$i];
  $files[$i] =~ s/\./_/;
  `mv $prev $files[$i]`;

  my ($nodir) = $files[$i] =~ /.*\/(.+)$/ ;
#  print "File is $files[$i] nodir is $nodir\n" ;
#  `cd $dir; bedtools intersect -u -a $files[$i] -b $intfile > ../u/$files[$i]_intout.u`;
#  `cd $dir; bedtools intersect -v -a $files[$i] -b $intfile > ../v/$files[$i]_intout.v`;
  `cd $dir; bedtools intersect -u -a $nodir -b $intfile > ../u/$nodir\_intout.u`;
  `cd $dir; bedtools intersect -v -a $nodir -b $intfile > ../v/$nodir\_intout.v`;
  
  $cmdu .= "u/$nodir\_intout.u ";
  $cmdv .= "v/$nodir\_intout.v ";
}

print "Running mapping command for u/\n"; 
`$cmdu; mv *.txt u/`;

print "Running mapping command for v/\n"; 
`$cmdv; mv *.txt v/`;

my $r = "
library(ggplot2)
library(reshape)
";

my @mapu = <u/*.txt>;
my @mapv = <v/*.txt>;
my @mapfilesu;
my @mapfilesv;
my %namesu;
my %namesv;

print "Making R script\n";
for (my $n = 0; $n < @mapu; $n++) {
  my ($varname) = $mapu[$n] =~ /_(.+)_.+\.txt$/;
  $varname .= "_u";
  $r .= "\n$varname<-read.delim(\"$mapu[$n]\", header=F)\n$varname<-$varname\$V4\n";

  my $tmp = `wc -l < $mapu[$n]`; # may not work
  chomp $tmp;
  $mapfilesu[$n]{count} = $tmp;
  $mapfilesu[$n]{var} = $varname;

  my ($base) = $mapu[$n] =~ /\/(.+)_[s|b].+$/;
  if ($varname =~ /shuffled/) {
    $namesu{$base}{shuffled} = $n;
  }
  elsif ($varname =~ /bed/) {
    $namesu{$base}{bed} = $n;
  }
}

for (my $m = 0; $m < @mapv; $m++) {
  my ($varname) = $mapv[$m] =~ /_(.+)_.+\.txt$/;
  $varname .= "_v";
  $r .= "\n$varname<-read.delim(\"$mapv[$m]\", header=F)\n$varname<-$varname\$V4\n";

  my $tmp = `wc -l < $mapv[$m]`; # may not work
  chomp $tmp;

  $mapfilesv[$m]{count} = $tmp;
  $mapfilesv[$m]{var} = $varname;

  my ($base) = $mapv[$m] =~ /\/(.+)_[s|b].+$/;

  if ($varname =~ /shuffled/) {
    $namesv{$base}{shuffled} = $m;
  }
  elsif ($varname =~ /bed/) {
    $namesv{$base}{bed} = $m;
  }
}



$r .= "\nshuffle=NULL\ndata=NULL\n";

foreach my $bases (keys %namesu) {
  my $varu_b = $mapfilesu[$namesu{$bases}{bed}]{var};
  my $countu_b = $mapfilesu[$namesu{$bases}{bed}]{count};
  my $varv_b = $mapfilesv[$namesv{$bases}{bed}]{var};
  my $countv_b = $mapfilesv[$namesv{$bases}{bed}]{count};

  if ($countu_b > $countv_b) {
    $r .= "sample_$bases\_b<-$varu_b\[c(sample(1:NROW($varu_b), $countv_b, replace=FALSE))]\n";
    $r .= "data<-c(data, abs($varv_b - sample_$bases\_b))\n" ; # appends to end of vector
  }
  else {
    $r .= "sample_$bases\_b<-$varv_b\[c(sample(1:NROW($varv_b), $countu_b, replace=FALSE))]\n";
    $r .= "data<-c(data, abs($varu_b - sample_$bases\_b))\n" ; # appends to end of vector
  }

  my $varu_s = $mapfilesu[$namesu{$bases}{shuffled}]{var};
  my $countu_s = $mapfilesu[$namesu{$bases}{shuffled}]{count};
  my $varv_s = $mapfilesv[$namesv{$bases}{shuffled}]{var};
  my $countv_s = $mapfilesv[$namesv{$bases}{shuffled}]{count};

  if ($countu_s > $countv_s) {
    $r .= "sample_$bases\_s<-$varu_s\[c(sample(1:NROW($varu_s), $countv_s, replace=FALSE))]\n";
    $r .= "shuffle<-c(shuffle, abs($varv_s - sample_$bases\_s))\n" ; # appends to end of vector
  }
  else {
    $r .= "sample_$bases\_s<-$varv_s\[c(sample(1:NROW($varv_s), $countu_s, replace=FALSE))]\n";
    $r .= "shuffle<-c(shuffle, abs($varu_s - sample_$bases\_s))\n" ; # appends to end of vector
  }
}

#$r .= "\nu=NULL\nv=NULL\n";


### incorrect analysis
#foreach my $bases (keys %namesu) {
#  print "namesu bases $bases\n";

#  my $var = $mapfilesu[$namesu{$bases}{shuffled}]{var};
#  my $count = $mapfilesu[$namesu{$bases}{bed}]{count};

#  print "bases is $bases\nnamesu{bases}{bed} is $namesu{$bases}{bed}\n";
#  $r .= "sample_$var<-$var\[c(sample(1:NROW($var), $count, replace=FALSE))]\n";
#  $r .= "u<-c(u, abs($var - sample_$var))\n" ; # appends to end of vector
#}

#foreach my $bases (keys %namesv) {
#  print "namesv bases $bases\n";

#  my $var = $mapfilesv[$namesv{$bases}{shuffled}]{var};
#  my $count = $mapfilesv[$namesv{$bases}{bed}]{count};
#  $r .= "sample_$var<-$var\[c(sample(1:NROW($var), $count, replace=FALSE))]\n";
#  $r .= "v<-c(v, abs($var - sample_$var))\n"; # appends to end of vector
#}
### incorrect analysis

#$r .= "matrix<-list(data.frame(U=u), data.frame(V=v))
$r .= "matrix<-list(data.frame(Data=log10(data)), data.frame(Shuffle=log10(shuffle)))
matrix<-melt(matrix)
plot<-ggplot(matrix, aes(variable, value))+
geom_boxplot(aes(fill=variable))

pdf(\"test.pdf\")
plot
dev.off()
"; 

open (OUT, ">", "Rscript.R");
print OUT $r;
close OUT;
