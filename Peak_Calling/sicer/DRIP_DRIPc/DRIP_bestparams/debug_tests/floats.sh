#!/bin/bash

#i=0.1
#while [ "`echo "$i*.001" | bc -l`" != ".0000000001" ] 
#do
#  i="`echo "$i*.001" | bc -l`"
#  echo "$i"
#done
i=.1
while [ $i != ".0000000001" ] 
do
  i="`echo "$i*.001" | bc -l`"
  echo "$i"
done
