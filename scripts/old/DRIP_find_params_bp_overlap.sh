#!/bin/bash

function count() {
  local filename=$1
  local total=0
  cut -f 2-3 $filename > tempfile.tmp
  while read line
    do 
      local str=`echo ${line% *}`
      local first=`echo ${str% *}`
      local last=`echo ${str##* }`
      local total=$(($total + ($last - $first)))
    done < tempfile.tmp
  rm tempfile.tmp
  echo $total 
}

LARGE_E=.00005 #modified in loop
SMALL_E=.00000000000000000005 #last E value tested
#cannot get more than 19 0's smallest E is 5E-20
SICER_DIR=/data/aparna/SICER1.1/SICER
BED1=chr19file1.bed
BED2=chr19file2.bed
BED_OVERLAP=intersect_bp_DRIPc_OUT.bed
DRIP=drip_chr19.bed
#mkdir temp1
#mkdir temp2
mkdir drip_temp
echo -e "E-value\tWindow_Size\tGap_Size\tDRIPc_num_intersects\tDRIPc_bp_overlap\tDRIPc_File1_peaks\tDRIPc_File1_bp\tDRIPc_File2_peaks\tDRIPc_file2_bp\tDRIP_num_intersects\tDRIP_bp_overlap\tDRIP_file_peaks\tDRIP_bp\tDRIP_Percent_Overlap_bp" > drip_summary_file.tsv
#FIXME running command from best_params.pl and the below bedtools command work fine in terminal but output nothing here.
#rest of script works if the three commands are first run by user then this script is run 
#use best params unfiltered for the two beds
#           sh $SICER_DIR/SICER-rb.sh . $BED1 ./temp1 hg19 1 350 150 0.74 700 .000000000000005
#           sh $SICER_DIR/SICER-rb.sh . $BED2 ./temp2 hg19 1 350 150 0.74 700 .000000000000005
#           bedtools intersect -wo -a temp1/*.scoreisland -b temp2/*.scoreisland > bed_intersect_outfile.bed
# ./overlaps.pl bed_intersect_outfile.bed
# mv intersect_outfile.bed intersect_bp_DRIPc_OUT.bed
# cat intersect_bp_DRIPc_OUT.bed | perl -pi -e 's/(.+)\t(.+)\t(.+)\t(.+)\t.+/$1\t$2\t$3\t$4/' > nolength_intersect_out.bed

peaks1=`cat temp1/*.scoreisland | wc -l`
peaks2=`cat temp2/*.scoreisland | wc -l`
bp_count_1=$(count temp1/*.scoreisland)
bp_count_2=$(count temp2/*.scoreisland)
bed_intersects=`cat $BED_OVERLAP | wc -l`
bp_bed_overlap=$(count $BED_OVERLAP)

while [ $LARGE_E != $SMALL_E ]
  do
    echo "$LARGE_E"
    for i in {50..400..50} #window size
      do 
        for j in {0..6} #gap size
          do
            gap=$(($j * $i))
            sh $SICER_DIR/SICER-rb.sh . $DRIP ./drip_temp hg19 1 $i 150 0.74 $gap $LARGE_E
            #note : sh is mapped to bash on this account used to run this script
            bedtools intersect -wo -a drip_temp/*.scoreisland -b nolength_intersect_out.bed > intersect_outfile.tmp
            ./overlaps.pl intersect_outfile.tmp
            rm intersect_outfile.tmp
            drip_bp=$(count drip_temp/*.scoreisland)
            drip_int=`cat intersect_outfile.bed | wc -l`
            drip_peaks=`cat drip_temp/*.scoreisland | wc -l`
            while read line
              do
                num=`echo ${line##* }`
                num=`echo ${num##* }`
                total_bp=$(($total_bp + $num))
              done < intersect_outfile.bed
            percent_bp_drip="`echo "$total_bp / $drip_bp * 100" | bc -l`"
            rm intersect_outfile.bed         
            rm drip_temp/*
            echo -e "$LARGE_E\t$i\t$gap\t$bed_intersects\t$bp_bed_overlap\t$peaks1\t$bp_count_1\t$peaks2\t$bp_count_2\t$drip_int\t$total_bp\t$drip_peaks\t$drip_bp\t$percent_bp_drip" >> drip_summary_file.tsv
            total_bp=0
          done
      done
   LARGE_E="`echo "$LARGE_E*.00001" | bc -l`"
  done
rm -r drip_temp
