#!/bin/bash

# use geoname ID field in a TSV to retrieve records from geonames SQLite db
# see geonames2sqlite.sh to build that db
# user args: 1) input TSV with project id, geoname id, and precision code, 2) number of geoname id field in input TSV, 3) geonames sqlite db
# example use: $0 tk.tsv 2 allCountries_2014-09-29.sqlite

incsv=$1
geoid=$2
db=$3
tmp=$(mktemp)
# write the start of a single SQL transaction to tmp file
echo "BEGIN;" > $tmp
# get list of unique goename IDs
geoids=$( 
	awk -F'\t' "{print \$${geoid}}" $incsv |\
	sed '1d' |\
	sort |\
	uniq 
)
# write SQL select statements to get whole records given geoname IDs
echo "$geoids" |\
awk -F'\t' -v a="'" '{print "select * from geonames where geonameid =",a$0a";"}' >> $tmp
# write the end of a single SQL transaction to tmp file
echo "COMMIT;" >> $tmp
# run that tmp SQL file to get whole records given geoname IDs
cat $tmp |\
sqlite3 $db
rm $tmp
