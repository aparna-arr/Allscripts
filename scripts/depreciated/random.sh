#!/bin/bash

#runs a random window generator and overlaps peaks to see if APOBEC peak overlap
#with DRIPc was significant

for i in {1..10000}
do
bedtools random -l 3008 -n 168 -g hg19_chr_length.txt > temp 
bedtools intersect -a temp -b DRIPC_peaks_mod_noheader.bed | wc -l >> test.txt 
done
