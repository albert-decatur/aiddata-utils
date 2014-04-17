#!/bin/bash

# given an input TSV with URL columns, make a TSV of URLs and their headers
# args: 1) input TSV 2) double quoted list of URL fields by number

# prepare the space separated double quoted list of URL fields to be used by awk
fieldList=$(
	echo $2 |\
	tr ' ' '\n'|\
	sed 's:^:$:g'|\
	tr '\n' ','|\
	sed 's:,$::g'
)

# print header
echo -e "URL\tHTTP header"
# for every unique URL, print URL and the HTTP header returned by curl
cat $1 |\
awk -F'\t' "{OFS=\"\t\";print $fieldList}"|\
grep -E "^http"|\
awk '{print $1}'|\
sort|\
uniq|\
parallel --gnu '
	header=$(
		curl -sI {} |\
	 	grep -E "HTTP.*[0-9]+" 
	)
	echo -e {}"\t$header"
'
