#!/bin/bash

while read line 
do
  num=`perl -pi -e 's/.+\t.+\t.+\t.+\t.+\t.+\t(.+)/$1/'`
  num1=${num/.*}
  if [ $num1 -lt 200 ]
    then
      echo $line > newfile
  fi
done < file

