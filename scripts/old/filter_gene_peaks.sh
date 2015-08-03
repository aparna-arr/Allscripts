#!/bin/bash

if [ $# -lt 6 ]
  then
    echo "usage: $0 <5col_refseq.bed> <+ peakfile> <- peakfile> <upstream_window> <downstream_window> <outdir>"
    exit 1 
fi

refseq=$1
plus_peaks=$2
minus_peaks=$3
up_wind=$4
down_wind=$5
out=$6

mkdir temp
mkdir $out

plus_ref="plus_$refseq"
minus_ref="minus_$refseq"

grep + $refseq > $plus_ref
grep - $refseq > $minus_ref

awk '{print $1 "\t" $2 "\t" $2 "\t" $5}' $plus_ref > temp/TSSonly_plus.bed
awk '{print $1 "\t" $3 "\t" $3 "\t" $5}' $minus_ref > temp/TSSonly_minus.bed

plus_around="$up_wind-up-$down_wind-down-TSS-plus.bed"
minus_around="$up_wind-up-$down_wind-down-TSS-minus.bed"

awk -v up=$up_wind -v down=$down_wind '{print $1 "\t" $2 - up "\t" $2 + down "\t" $5}' $plus_ref > temp/$plus_around
awk -v up=$up_wind -v down=$down_wind '{print $1 "\t" $3 - down "\t" $3 + up "\t" $5}' $minus_ref > temp/$minus_around

bedtools intersect -c -a temp/$plus_around -b temp/TSSonly_minus.bed > temp/numints_$plus_around
bedtools intersect -c -a temp/$minus_around -b temp/TSSonly_plus.bed > temp/numints_$minus_around

filter_genes.pl temp/numints_$plus_around $plus_ref
mv no_antisense_present.bed $out/noantisenseTSS_genes_$plus_around
mv antisense_present.bed $out/antisenseTSS_genes_$plus_around

filter_genes.pl temp/numints_$minus_around $minus_ref
mv no_antisense_present.bed $out/noantisenseTSS_genes_$minus_around
mv antisense_present.bed $out/antisenseTSS_genes_$minus_around

bedtools intersect -v -a temp/$plus_around -b temp/TSSonly_minus.bed > temp/noantisenseTSS_$plus_around
bedtools intersect -v -a temp/$minus_around -b temp/TSSonly_plus.bed > temp/noantisenseTSS_$minus_around

plus_up="$up_wind-upstream-noantisenseTSS-plus.bed"
minus_up="$up_wind-upstream-noantisenseTSS-minus.bed"

awk -v up=$up_wind '{print $1 "\t" $2 "\t" $2 + up "\t" $4}' temp/noantisenseTSS_$plus_around > temp/$plus_up
awk -v up=$up_wind '{print $1 "\t" $3 - up "\t" $3 "\t" $4}' temp/noantisenseTSS_$minus_around > temp/$minus_up

bedtools intersect -u -a temp/$plus_up -b $minus_peaks > temp/antipeak_$plus_up
bedtools intersect -u -a temp/$minus_up -b $plus_peaks > temp/antipeak_$minus_up

filtergenes_compareTSS.pl temp/antipeak_$plus_up $plus_ref 
mv filteredout.bed $out/antipeak_genes_$plus_up

filtergenes_compareTSS.pl temp/antipeak_$minus_up $minus_ref
mv filteredout.bed $out/antipeak_genes_$minus_up

rm -r temp
