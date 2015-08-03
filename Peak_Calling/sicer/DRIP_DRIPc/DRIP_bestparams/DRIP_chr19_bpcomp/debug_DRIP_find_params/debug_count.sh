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

bp_count_1=$(count temp1/*.scoreisland)
echo $bp_count_1
