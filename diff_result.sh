#!/bin/bash
TARGET="sorted_1_rnd.txt"
for FILE in sorted_*_*.txt sorted_**_*.txt 
do
	echo "compare $TARGET and $FILE"
	diff -q $TARGET $FILE
done
