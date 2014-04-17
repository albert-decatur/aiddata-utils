#!/bin/bash

# outputs yyyy-mm-dd formated dates from dd/mm/yyyy formatted dates, as well as first field from input TSV (to help join)
# args: 1) input TSV 2) double quoted list of date fields
# NB: assumes first field is ID field

# print the list of fields the user is interested in for awk
fieldList=$(
	echo $2 |\
	tr ' ' '\n' |\
	sed 's:^:$:g' |\
	tr '\n' ',' |\
	sed 's:,$::g' \
)

# get the count of fields of interest plus 1
count_fields=$(
	echo "$2"|\
	wc -w
)
count_fields=$((count_fields+1))

# print header of relevant fields
cat $1 | awk -F"\t" "{OFS=\"\t\";print \$1,${fieldList}}" | sed -n '1p'

# print the first field of the input TSV, plus the input field as yyyy-mm-dd
cat $1 |\
sed '1d'|\
awk -F"\t" "{OFS=\"\t\";print \$1,${fieldList}}" |\
parallel --gnu \
	'id=$( echo {} | awk -F"\t" "{print \$1}" )
	isodates=$(
	for i in $(seq 2 '$count_fields') 
	do 
		date=$( echo {} | awk -F"\t" "{print \$${i}}");
		if [[ -n "$date" ]]; then
			echo "$date" | awk -F"/" "{OFS=\"-\";print \$3,\$2,\$1}"
		else
			echo " "
		fi
	done |\
	tr "\n" "\t"|\
	sed "s: ::g"	
	)
	echo -e "$id\t$isodates"'
