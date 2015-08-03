
# 8/27/14 explore link between MALAT1 and NEAT1 binding sites and dripc data
# data from West, J. A., Davis, C. P., Sunwoo, H., Simon, M. D., Sadreyev, R. I., Wang, P. I., et al. (2014). The Long Noncoding RNAs NEAT1 and MALAT1 Bind Active Chromatin Sites. Molcel, 1–12. doi:10.1016/j.molcel.2014.07.012

cd /data/wearn/NT2_dripc/West_lncRNA

  670 MALAT1_chart_peaks.bed
 1251 NEAT1_chart_peaks.bed

intersectBed -u -a NEAT1_chart_peaks.bed -b ../Peaks/NT2_DRIPc_merged_rep12_peaks.bed | wc -l
934 (75%)
intersectBed -u -a MALAT1_chart_peaks.bed -b ../Peaks/NT2_DRIPc_merged_rep12_peaks.bed | wc -l
530 (79%)
intersectBed -u -a NEAT1_chart_peaks.bed -b ../Peaks/NT2_DRIP_intersect_peaks.bed | wc -l
1042 (83%)
intersectBed -u -a MALAT1_chart_peaks.bed -b ../Peaks/NT2_DRIP_intersect_peaks.bed | wc -l
574 (86%)

# most of these 2 lncRNAs' targets were also identified by DRIP and DRIPc!
# is it possible that DRIP signal is higher than DRIPc signal
# because if these lncRNAs act in trans
# the DNA for the target will be identified in DRIP
# but the RNA will not! because the RNA comes from MALAT1 and NEAT1!

# find malat1 and neat1 peaks that are in drip but not dripc
# ie potential trans genomic loci
intersectBed -u -a NEAT1_chart_peaks.bed -b ../Peaks/NT2_DRIP_intersect_peaks.bed > neat1_drip.bed
intersectBed -u -a MALAT1_chart_peaks.bed -b ../Peaks/NT2_DRIP_intersect_peaks.bed > malat1_drip.bed
intersectBed -v -a neat1_drip.bed -b ../Peaks/NT2_DRIPc_merged_rep12_peaks.bed > neat1_drip_not_dripc.bed
intersectBed -v -a malat1_drip.bed -b ../Peaks/NT2_DRIPc_merged_rep12_peaks.bed > malat1_drip_not_dripc.bed

   63 malat1_drip_not_dripc.bed
  124 neat1_drip_not_dripc.bed

#######################################

# 8/28/14 explore DRIP vs DRIPc difference using MAnorm
# aparna was working on this
# so i will get some files from her
# need to refer to her notebook to see exactly what she did

cd /data/wearn/NT2_dripc/MAnorm
cp /data/aparna/MAnorm/MAnorm_result.xls .

# she used dripc as sample 1 and drip as sample 2
# from her notebook:

aparna@zeus:/data/aparna/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 >= 1)) {print}}' > dripc_unique_peaks.bed
aparna@zeus:/data/aparna/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 <= -1)) {print}}' > drip_unique_peaks.bed
aparna@zeus:/data/aparna/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 < 5) || (($7 > -1) && ($7 < 1))) {print}}' > not_unique_peaks.bed

# let me try different cut off
# $9 is -log10 p-value. >5 means that it's less than 0.00001
# M = log2 (Read density in sample 1/Read density in sample 2) and A = 0.5 × log2 (Read density in sample 1 × Read density in sample 2)

# 2-fold: M > 1
# 3-fold: M > 1.585
# 4-fold: M > 2
# 5-fold: M > 2.32
# 6-fold: M > 2.585
# 7-fold: M > 2.807
# 8-fold : M > 3
# 16-fold: M > 4

# to be conservative and sure that the difference is real
# i will use 16-fold difference and p of 10e-5

sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 >= 4)) {print}}' > dripc_unique.bed
sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 <= -4)) {print}}' > drip_unique.bed
sed 1d MAnorm_result.xls | awk '{if (($9 < 5) || (($7 > -4) && ($7 < 4))) {print}}' > common.bed

  108867 MAnorm_result.xls
  106265 common.bed
    2367 drip_unique.bed
     234 dripc_unique.bed

# more drip unique than dripc unique!
# which fits my hypothesis that there are more trans genomic loci

# see if drip and dripc peaks overlap with neat1 and malat1
# add 2 more columns to manorm_results
# if overlap with neat1 / malat1, will be > 0 using intersect -c

intersectBed -c -a MAnorm_result_nohead.xls -b /data/wearn/NT2_dripc/West_lncRNA/NEAT1_chart_peaks.bed > MAnorm_result_neat1.txt
intersectBed -c -a MAnorm_result_neat1.txt -b /data/wearn/NT2_dripc/West_lncRNA/MALAT1_chart_peaks.bed > MAnorm_result_neat1_malat1.txt

awk '{if (($10 > 0) && ($11 == 0)) {print "n"} else if (($10 == 0) && ($11 > 0)) {print "m"} else if (($10 > 0) && ($11 > 0)) {print "nm"} else {print 0}}' MAnorm_result_neat1_malat1.txt > temp
paste MAnorm_result_nohead.xls temp > MAnorm_result_nm.txt

cat MAnorm_result_nm.txt  | awk '{if ($9 >= 5) {print}}' > significant.bed
cat MAnorm_result_nm.txt  | awk '{if ($9 < 5) {print}}' > not_significant.bed
# break down significant points by fold-change
awk '{if (($7 <= -4) || ($7 >= 4)) {print > "sig_16fold.bed"} else {print > "temp"}}' significant.bed
awk '{if (($7 <= -3) || ($7 >= 3)) {print > "sig_8fold.bed"} else {print > "temp2"}}' temp
awk '{if (($7 <= -2) || ($7 >= 2)) {print > "sig_4fold.bed"} else {print > "temp3"}}' temp2
awk '{if (($7 <= -1) || ($7 >= 1)) {print > "sig_2fold.bed"} else {print > "sig_lt2fold.bed"}}' temp3


   2601 sig_16fold.bed
  28062 sig_2fold.bed
  16185 sig_4fold.bed
   5986 sig_8fold.bed
  15666 sig_lt2fold.bed
  68500 total

68500 significant.bed
40366 not_significant.bed

R --no-save < plot_maplot.R
# plot is toooooo pretty!
# red dots are neat1 targets, blue dots are malat1 targets, purple dots are co-targets
# gray scale indicate fold change between dripc and drip
# each dot is a peak (dripc or drip)
# lightest gray in the middle is p > 10e-5 ie not significant

# my plot shows that most neat1 and malat1 targets are high in drip and low in dripc!!!!!
# trans r-loops ftw

# trying other cutoffs
sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 >= 2)) {print}}' | wc -l
sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 <= -2)) {print}}' | wc -l
sed 1d MAnorm_result.xls | awk '{if (($9 < 5) || (($7 > -2) && ($7 < 2))) {print}}' | wc -l

# 8-fold
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 >= 3)) {print}}' | wc -l
1245 # dripc specific
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 <= -3)) {print}}' | wc -l
7342 # drip specific
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 < 5) || (($7 > -3) && ($7 < 3))) {print}}' | wc -l
100279

# 4-fold
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 >= 2)) {print}}' | wc -l
7438
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 >= 5) && ($7 <= -2)) {print}}' | wc -l
17334
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ sed 1d MAnorm_result.xls | awk '{if (($9 < 5) || (($7 > -2) && ($7 < 2))) {print}}' | wc -l
84094

wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ wc -l /data/wearn/NT2_dripc/Peaks/NT2_DRIP_intersect_peaks.bed
58410 /data/wearn/NT2_dripc/Peaks/NT2_DRIP_intersect_peaks.bed
wearn@zeus:/data/wearn/NT2_dripc/MAnorm$ wc -l /data/wearn/NT2_dripc/Peaks/NT2_DRIPc_merged_rep12_peaks.bed
50823 /data/wearn/NT2_dripc/Peaks/NT2_DRIPc_merged_rep12_peaks.bed

108866 MAnorm_result_nohead.xls

# find all lncRNA sources and targets
# see if dripc specific peaks are sources!!!
# location analysis of sources/targets