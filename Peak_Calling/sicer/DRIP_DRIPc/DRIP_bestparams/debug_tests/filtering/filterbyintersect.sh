#!/bin/bash

bedtools intersect -u -a temp1/*.scoreisland -b temp2/*.scoreisland > intersect_outfile.tmp
           while read line
            do
              num=`echo ${line##* }`
              #note : 1 space in above expr. 
              num=${num/.*}
              num=`echo ${num##* }`
              #note : 1 space in above expr. 
              if [ $num -gt 150 ]
                then
                  echo "$line" >> intersect_outfile.bed
              fi
             done < intersect_outfile.tmp

