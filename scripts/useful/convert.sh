#!/bin/bash

in=$1
out=$2
warning="Warnings:\nConverts .gff to .bed\n"
if [ $# -lt 2 ]
  then
    echo "usage: $0 <in.gff> <out.bed>"
    echo -e "\n$warning"
    exit 1
fi

echo -e "\n$warning"

awk '{print $1 "\t" $4 "\t" $5}' $in > $out


