#!/bin/bash

# given a TSV with URL fields, concatenate them into a single URL field, separating with pipes
# args: 1) input TSV, 2) double quoted space separated list of fields with URLs
# output is first field (assumed to be unique ID) and a pipe seaprated list of URLs found in any of the given fields

urlFields=$2
fieldList=$(
	echo "$urlFields" |\
	tr ' ' '\n' |\
	sed 's:^:\\$:g'
)

cat $1 |\
sed '1d'|\
parallel --gnu '
	id=$( echo {} | awk -F"\t" "{print \$1}")
	urls=$( echo {} | awk -F"\t" "{print ${fieldList}}" | grep -oE "http\S+" | sort | uniq | tr "\n" "|" | sed "s:|$::g")
	urlCount=$( echo "$urls" | grep -vE "^$" | wc -l )
	if [[ $urlCount -gt 0 ]]; then 
		echo -e "$id\t$urls"
	else 
		echo -e "$id\t"
	fi
'
