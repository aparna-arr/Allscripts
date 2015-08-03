#!/bin/bash          
        for file in temp1/*.scoreisland temp2/*.scoreisland
          do
            echo $file
            while read line
              do
                num=`echo ${line##* }`
                num=${num/.*}
                num=`echo ${num##* }`
                if [ $num -gt 150 ] #score cutoff
                  then
                    echo $line >> file
                fi
              done < $file
            rm $file
            mv file "$file.NEW"
          done
          bedtools intersect -u -a temp1/*.scoreisland.NEW -b temp2/*.scoreisland.NEW > intersect_outfile.bed


