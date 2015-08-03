#!/bin/bash

function overlap() {
  IN=( ${!1// / } )
  local tempname
  local TMP
  for ((i=0;i<${#IN[@]}-1;i++))
    do
      j=$(($i+1))
      `bedtools intersect -wo -a ${IN[$i]} -b ${IN[$j]} > tempfile.tmp`
      overlaps_7col.pl tempfile.tmp
      tempname="${IN[$i]}_temp_$i-$j.tmp"
      cp intersect_outfile.bed $tempname
      TMP[${#TMP[@]}]=$tempname
      rm tempfile.tmp
    done
    echo ${TMP[@]}
}

if [ $# -lt 1 ]
  then
    echo "usage: $0 <origin file dir>"
    exit 1
fi

for f in $1/*
  do
    if [[ $f == *early* ]] 
      then      
        EARLY[${#EARLY[@]}]=$f
    elif [[ $f == *late* ]]
      then
        LATE[${#LATE[@]}]=$f
    fi
  done
while [ ${#EARLY[@]} -gt 1 ] 
  do
    result=$(overlap EARLY[@])
    EARLY=()
    EARLY=( ${result// / } )
  done

while [ ${#LATE[@]} -gt 1 ]
  do
    result=$(overlap LATE[@])
    LATE=()
    LATE=( ${result// / } )
  done
early=${EARLY[0]}
late=${LATE[0]}
mv $early common_early_origins.bed
mv $late common_late_origins.bed 
