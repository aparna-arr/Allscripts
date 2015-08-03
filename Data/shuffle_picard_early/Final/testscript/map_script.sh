#!/bin/bash

if [ $# -lt 4 ]
  then
    echo "usage: $0 <.shuffled .bed dir/> <file to map> <file to intersect> <cache/>"
    exit 1
fi

dir=$1 # directory with .shuffled .bed files
map=$2 # file to map against
intfile=$3 # file to do -u -v against
cache=$4 # cache for map_wig_to_bed_BIG.pl

echo "Dependencies: map_wig_to_bed_BIG.pl"

echo "Making temp directories u/ and v/"

mkdir u
mkdir v

echo "Making -u -v files"

for f in $dir*
  do
    # rename .shuffled to _shuffled
    # and .bed to _bed
    if [[ $f == *.shuffled ]]
      then
        mv $f ${f%.shuffled}_shuffled
    fi
    
    if [[ $f == *.bed ]]
      then
        mv $f ${f%.bed}_bed
    fi
  done

cd $dir
for f in *
  do 
#    echo $f
    # create -u -v files, place in directory
    bedtools intersect -u -a $f -b $intfile > ../u/$f.u
    bedtools intersect -v -a $f -b $intfile > ../v/$f.v
  done

cd ..
echo "Starting map for -u"

cmd="perl -I /usr/local/bin/Perl/ /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -w $map -r $cache "
for f in u/*
  do 
    # add each bed file to the command string
    cmd="$cmd $f"
  done

$cmd 

names

for f in *.txt
  do
    names[]  
  done


echo "Moving all .txt files to u/"

mv *.txt u/

echo "Starting map for -v"

cmd="perl -I /usr/local/bin/Perl/ /usr/local/bin/Perl/map_wig_to_bed_BIG.pl -m -w $map -r $cache "
for f in v/*
  do
    # add each bed file to the command string
    cmd="$cmd $f"
  done

$cmd 

echo "Moving all .txt files to v/"

mv *.txt v/

# run an R script here that either makes a plot or outputs summaries.


R="library(reshape)
library(ggplot2)"
count=0

for f in u/*.txt v/*.txt # may not work
  do
    R="$R
var$count<-read.delim(\"$f\", header=F)
var$count<-var$count\$V4";
    ((count++))
  done

R="$R
matrix<-list("

newcount=0
for f in u/*.txt
  do
    R="$R data.frame($f=log10(var$newcount), group=\"u\"),"
    ((newcount++))
  done

for f in v/*.txt
  do
    R="$R data.frame($f=log10(var$newcount), group=\"v\"),"
    ((newcount++))
  done

R="$R)
matrix<-melt(matrix)

plot<-ggplot(matrix, aes(variable, value))+
geom_boxplot(aes(fill=group))+
";

echo "R script is Rscript.R"

echo "$R" > Rscript.R
