#!/bin/bash

# listpairs.sh
# for a double quoted list of items, print all pairs separated by user specificed delimiter
# user args: 1) double quoted list of items, 2) user specified delimiter
# example use: $0 "yo sup homie" "|"

d=$2

set -- $1
for a
do 
	shift
	for b
	do 
		printf "%s$d%s\n" "$a" "$b"
	done
done
