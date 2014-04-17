#!/bin/bash

# args: 1) input TSV, 2) regexp for null
# return TSV showing the percent of every field that matches null value provided
# example use: $0 amp.csv "^\s*$|0"

echo -e "field_name\tfield_num\tcount_null\tprct_null"
intsv=$1
linecount=$( cat $intsv | wc -l )
echo $intsv | parallel --gnu '
	numfields=$( cat {} | sed -n "1p" | tr "\t" "\n" | wc -l )
	for fieldnum in $( seq 1 $numfields ); do
		countnull=$( cat {} | awk -F"\t" "{print \$${fieldnum}}" | grep -E "'$2'" | wc -l )
		ratio=$( echo "scale=4; $countnull / '$linecount' * 100" | bc )
		fieldname=$( cat {} | sed -n "1p" | awk -F"\t" "{print \$${fieldnum}}" )
		echo -e "$fieldname\t$fieldnum\t$countnull\t$ratio"
	done
'
