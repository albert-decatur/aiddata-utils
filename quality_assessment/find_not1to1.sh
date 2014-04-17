#!/bin/bash

# given a TSV with some ID field and a value field, find instances where the ID has more than one unique value
# args: 1) input TSV, 2) field number of ID, 3) field number of value
# eg: ID field in "Project ID" and value field is "Project Title"

# get unique list of IDs from ID field
cat $1 |\
sed '1d' |\
awk -F'\t' "{print \$$2}" |\
sort |\
uniq |\
# for every unique ID, check how many unique values.  if more than one, report unique ID
parallel --gnu '
	count_values=$( 
		cat '$1' |\
		awk -F"\t" "{if(\$'$2' == \"{}\")print \$'$3'}" |\
		sort |\
		uniq |\
		wc -l 
	)
	if [[ "$count_values" -gt 1 ]]; then 
		echo {}
	fi
'
