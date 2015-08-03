#!/bin/bash

total_bp=0
 while read line
              do
#                echo "DO"
                num=`echo ${line##* }`
                num=`echo ${num##* }`
#                echo "{$num}"
                total_bp=$(($total_bp + $num))
#                echo "[$num]"
#                echo "($total_bp)"
              done < intersect_outfile.bed
#echo $total_bp
