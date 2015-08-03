#!/bin/bash

# DRIPc find_params script
# no bp intersections peak number only
# all bedtools -u
# filtering uncommented


LARGE_E=.00005 #modified in loop
SMALL_E=.00000000000000000005 #last E value tested
#cannot get more than 19 0's smallest E is 5E-20
SICER_DIR=/data/aparna/SICER1.1/SICER
BED1=chr19file1.bed
BED2=chr19file2.bed
mkdir temp1
mkdir temp2
echo -e "E-value\tWindow_Size\tGap_Size\tNum_Intersects\tFile1_peaks\tFile2_peaks\tPercent_Overlap" > summary_file.tsv
while [ $LARGE_E != $SMALL_E ]
 do
   echo "$LARGE_E"
   for i in {50..400..50} #window size
     do 
       for j in {0..6} #gap size
         do
           gap=$(($j * $i))
           sh $SICER_DIR/SICER-rb.sh . $BED1 ./temp1 hg19 1 $i 150 0.74 $gap $LARGE_E
           sh $SICER_DIR/SICER-rb.sh . $BED2 ./temp2 hg19 1 $i 150 0.74 $gap $LARGE_E
           #note : sh is mapped to bash on this account used to run this script
    # for no filtering by score uncomment below
           #bedtools intersect -u -a temp1/*.scoreisland -b temp2/*.scoreisland > intersect_outfile.bed
    ################################
    # For filtering by score       #
    ################################
    # comment if no filtering by score
           bedtools intersect -u -a temp1/*.scoreisland -b temp2/*.scoreisland > intersect_outfile.tmp
           while read line
            do
              num=`echo ${line##* }`
              num=${num/.*}
              num=`echo ${num##* }`
              if [ $num -gt 150 ] #score cutoff
                then
                  echo $line >> intersect_outfile.bed
              fi
             done < intersect_outfile.tmp
           rm intersect_outfile.tmp
      ################################
           int_count=`cat intersect_outfile.bed | wc -l`           
           rm intersect_outfile.bed
           peaks1=`cat temp1/*.scoreisland | wc -l`
           peaks2=`cat temp2/*.scoreisland | wc -l`
           less_peaks=$peaks1
           if [ $peaks2 -lt $peaks1 ]
             then
               less_peaks=$peaks2
           fi
           percent_overlap="`echo "$int_count/$less_peaks*100" | bc -l`" 
           rm temp1/*
           rm temp2/*
           echo -e "$LARGE_E\t$i\t$gap\t$int_count\t$peaks1\t$peaks2\t$percent_overlap" >> summary_file.tsv
         done
     done
   LARGE_E="`echo "$LARGE_E*.00001" | bc -l`"
 done
rm -r temp1/ temp2/
