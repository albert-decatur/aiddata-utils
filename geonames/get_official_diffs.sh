#!/bin/bash

# just grab geonames.org own files that record modifications and deletions
# and put them in a dir labelled by date
# put this in cron to run each day
# user args: 1) directory to put these in
# geonames names files according to the date changes were made.  this script names dirs according to the date files were retrieved

dir=$1
for type in deletes modifications
do
	wget -c -np -nd -r -l 1 -A "${type}*.txt" -P $dir http://download.geonames.org/export/dump/
done

# rm robots.txt
find $dir/ -type f -iregex ".*robots[.]txt$" | xargs rm
