#!/bin/bash

num1=103.3462
num1=${num1/.*}
if [ $num1 -lt 200 ]
  then
    echo "$num1"
fi
