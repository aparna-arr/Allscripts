#!/bin/bash

warning="Warnings:\nDoes not add track type\nOutfile is same as input\n"

file=$1
name=$2
desc=$3 #optional

if [ $# -lt 2 ] 
  then
    echo "usage: $0 <file name > <track name> <optional description>"
    echo -e "\n$warning"
    exit 1
fi

echo -e $warning

line="track name=\"$name\" description=\"$desc\""

echo $line > $file\_header.tmp

cat $file\_header.tmp $file > $file\.new

mv $file\.new $file
rm $file\_header.tmp
