#!/bin/bash

function f() {
  NEW1=(${1[1]} ${!2} ${!3})
  NEW2=${!2}
  NEW3=${!3}
  echo new 1 is ${NEW1[@]}
  echo new 2 is ${NEW2[@]}
  echo new 3 is ${NEW3[@]}
  #echo "new 3 is ${NEW3[@]}"
  #echo "new 2 is ${NEW2[@]}"
  #echo "new 1 is ${NEW1[@]}"
  #NEW=("${!1}")
  #for i in ${NEW}
  #echo "my array is ${NEW[@]}"
}

ARRAY1=(one two three)
ARRAY2=(four six)
ARRAY3=(five)

f ARRAY1[@] ARRAY2[@] ARRAY3[@]

