#!/bin/bash

warning="Warnings:\nnograph_s50plot.R must be in same dir as this script!\n";

if [ $# -lt 1 ]
  then
    echo "usage: $0 <dir with CLEAN_s50_moremem.pl outfiles>"
    echo -e $warning
    exit 1 
fi

echo -e $warning

for f in $1/*
  do
    R --vanilla --args $f < nograph_s50plot.R
    chr=${f%_*} 
    chr=${chr##*/}
    echo "$chr" 
    awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' earlyorigins.txt >> early_origins_all.txt
    awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' lateorigins.txt >> late_origins_all.txt
    rm earlyorigins.txt lateorigins.txt
  done
