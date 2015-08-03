#!/bin/bash

function test_file {
  if [[ ! -f $1 ]]
    then
      echo "file does not exist! [$1]"
      exit 1
  fi
}

function not_blank {
  if [[ $1 == "" ]]
    then
      echo "no filename / nothing entered! [$1]"
      exit 1
  fi
}

function h {
  echo "notes.sh (alias n)"
  echo "usage : n <options> <filename(s)>"
  echo "options : -[olrcmpeh]"
  echo "-o : overwrite <filename>"
  echo "-l : ls -hl notes directory"
  echo "-r : rm <filename>"
  echo "-c : cat <file1> <file2> <newfile>"
  echo "-m : mv <file> <newfile>"
  echo "-p : print (cat) <file>"
  echo "-e : opens file in editor (vim)"
  echo "-h : prints help message"
}

DIR=/data/aparna/notes
EDITOR=vim

if [[ $# -lt 1 ]]
  then
    echo "usage: $0 <options> <filename>"
    exit 1
fi

if [[ ! $1 =~ "-" ]]
  then
    filename=$1
else
  option=$1
  if (( $# == 2 ))
    then
      filename=$2
  fi
fi

mode="a"

if [[ $option =~ "-" ]]
  then
    case $option in
      -*o*) mode="o" ;; # overwrite mode
      -*l*) ls -hl $DIR ; exit 0 ;;
      -*r*) test_file $DIR/$filename ; rm $DIR/$filename ; exit 0 ;;
      -*c*) test_file $DIR/$2 ; test_file $DIR/$3 ; not_blank $4 ; cat $DIR/$2 $DIR/$3 >> $DIR/$4; exit 0 ;; 
      -*m*) test_file $DIR/$2 ; not_blank $3 ; mv $DIR/$2 $DIR/$3 ; exit 0 ;; 
      -*p*) test_file $DIR/$2 ; cat $DIR/$2 ; exit 0 ;;
      -*e*) $EDITOR $DIR/$2 ; exit 0 ;;
      -*h*) h ; exit 0 ;;
      *) echo "option not recognized" ; exit 1 ;; 
    esac
fi

not_blank $filename 

while [[ $line != ":wq" ]]
  do
    read line
    if [[ $line != ":wq" ]]
      then
        if [[ $mode == "a" ]]
          then
            echo "$line" >> "$DIR/$filename"
        elif [[ $mode == "o" ]]
          then
            echo "$line" > "$DIR/$filename"
            mode="a"  #otherwise each line will keep overwriting file
        fi
    fi
  done
