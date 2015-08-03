#!/bin/bash

echo "Dependencies : overlap_origin_files.sh remove_duplicate_lines.pl makeint.pl" 
echo ""

if [ $# -lt 4 ]
  then
    echo "usage: $0 <DRIPc peakfile> <Parsed CpG file> <Gap file> <Dir with individual origin files no common>"
    exit 1
fi

DRIPc=$1
CpG=$2
GAP=$3
ORIGIN_DIR=$4

echo "making int"
echo "removing gaps"
echo "output is sorted"
for f in $ORIGIN_DIR/* ; do makeint.pl $f ; sort -k1,1 -k2,2n $f > $f.sort ; bedtools intersect -v -a $f.sort -b $GAP > $f ; rm $f.sort ; done

echo "merging"
for f in $ORIGIN_DIR/* ; do bedtools merge -d 50000 -i $f > $f.merged ; mv $f.merged $f ; done

echo "overlapping"
overlap_origin_files.sh $ORIGIN_DIR

echo "cleaning up outdir"
rm $ORIGIN_DIR/*.tmp

echo "removing duplicates"
remove_duplicate_lines.pl common_early_origins.bed
remove_duplicate_lines.pl common_late_origins.bed

echo "making int"
makeint.pl common_early_origins.bed
makeint.pl common_late_origins.bed

echo "sorting"
sort -k1,1 -k2,2n common_early_origins.bed > sort_common_early_origins.bed
sort -k1,1 -k2,2n common_late_origins.bed > sort_common_late_origins.bed

echo "rm and mv files"
mv sort_common_early_origins.bed common_early_origins.bed
mv sort_common_late_origins.bed common_late_origins.bed

rm intersect_outfile.bed 

echo ""
echo "Outfiles are common_early_origins.bed common_late_origins.bed"
echo "$ORIGIN_DIR contains sorted, merged, gaprm individual origin outfiles."
echo "There are no headers for any files"
echo ""

echo "Counts"
awk '{print $3-$2}' $DRIPc | awk '{sum+=$1} END {print "DRIPc count: "sum}'
awk '{print $3-$2}' $CpG | awk '{sum+=$1} END {print "CpG count: "sum}'
awk '{print $3-$2}' common_early_origins.bed | awk '{sum+=$1} END {print "Common Early count: "sum}'
awk '{print $3-$2}' common_late_origins.bed | awk '{sum+=$1} END {print "Common Late count: "sum}'
bedtools intersect -wo -a common_early_origins.bed -b $DRIPc | awk '{print $10}' | awk '{sum+=$1} END {print "DRIPc_early overlap count: "sum}'
bedtools intersect -wo -a common_late_origins.bed -b $DRIPc | awk '{print $10}' | awk '{sum+=$1} END {print "DRIPc_late overlap count: "sum}'
bedtools intersect -wo -a common_early_origins.bed -b $CpG | awk '{print $7}' | awk '{sum+=$1} END {print "CpG_early overlap count: "sum}'
bedtools intersect -wo -a common_late_origins.bed -b $CpG | awk '{print $7}' | awk '{sum+=$1} END {print "CpG_late overlap count: "sum}'



