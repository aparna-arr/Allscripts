#!/bin/bash
DIR=backup_2/

for f in *
do
tar cvzf $DIR/$f.tar.gz $f
done

