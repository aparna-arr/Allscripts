#!/bin/bash

warning="Warnings:\ntimespecific_nograph_s50plot.R must be in /data/aparna/replication_origins/s50/time_specific/!\n";

if [ $# -lt 1 ]
  then
    echo "usage: $0 <dir with CLEAN_s50_moremem.pl outfiles>"
    echo -e $warning
    exit 1 
fi

echo -e $warning

for f in $1/*
  do
    R --vanilla --args $f < /data/aparna/replication_origins/s50/time_specific/timespecific_nograph_s50plot.R
    chr=${f%_*} 
    chr=${chr##*/}
    echo "$chr"



 
    awk 'NF > 0' g1.txt | awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> g1_all.txt
    awk 'NF > 0' s1.txt | awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> s1_all.txt
    awk 'NF > 0' s2.txt | awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> s2_all.txt
    awk 'NF > 0' s3.txt | awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> s3_all.txt
    awk 'NF > 0' s4.txt |awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> s4_all.txt
    awk 'NF > 0' g2.txt | awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' >> g2_all.txt
#    awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' earlyorigins.txt >> early_origins_all.txt
#    awk -v chrom="$chr" '{print chrom "\t" $1 "\t" $2}' lateorigins.txt >> late_origins_all.txt
#    rm earlyorigins.txt lateorigins.txt
    rm g1.txt s1.txt s2.txt s3.txt s4.txt g2.txt
  done

# remove lines that just consist of chr and not position
