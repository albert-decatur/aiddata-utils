#!/bin/bash

# given a TSV, for each field, print the percent of lines in the document that would be duplicates if that field were missing
# in other words, that entires in that field are the only thing keeping those lines from being duplicates
# args: 1) input TSV

fieldCount=$(cat $1 | sed -n '1p' | tr '\t' '\n' | nl | awk '{print $1}' | sed -n '$p' )
current_lineCount=$(cat $1 | wc -l)
# print header
echo -e "field_name\tfield_num\tlineCount_wo\tprct_wouldBe_duplicate"

for i in $(seq 1 $fieldCount)
do 
	count=$( cat $1 | cut --complement -f $i | sort | uniq | wc -l )
	name=$(cat $1 | sed -n '1p' | tr '\t' '\n' | nl | grep -E "^\s+\b${i}\b" | awk '{OFS="";$1="";print $0}')
	ratio=$( echo "scale=4; 100 - ( $count / $current_lineCount * 100 )"|bc)
	echo -e "$name\t$i\t$count\t$ratio"
done
