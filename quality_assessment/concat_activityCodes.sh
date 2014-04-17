#!/bin/bash

# using a numeric range of activity code field numbers, return a list of prefixed with IDs to join or paste back to the original
# NB: activity code fields are assumed to be odd numbered. ID field assumed to be first field
# args: 1) input TSV with ID field and activity code fields 2) first activity code field number, 3) last activity code field number

ac_fields=$(
	for i in $(seq $2 $3)
	do 
		if [[ $((i % 2)) == 1 ]]; then 
			echo $i
		fi
	done  |\
	sed 's:^:$:g;s:^:\\:g' |\
	tr '\n' ',' |\
	sed 's:,$::g'
)

# print input TSV
cat $1 |\
# remove header
sed '1d' |\
# for every line of input TSV, print ID and activity code fields.
# sort activity codes numeric desc and take uniques.
# print ID, then tab, then pipe separated activity code list
parallel --gnu 'id_and_ac=$( echo {} | awk -F"\t" "{OFS=\"\t\";print \$1,'$ac_fields'}" ); ac=$( echo "$id_and_ac" | awk -F"\t" "{OFS=\"\t\";\$1=\"\";print \$0}" | tr "\t" "\n"| sort -n | uniq | tr "\n" "|" | sed "s:$:\n:g" | sed "s:|\+:|:g;s:^|::g;s:|$::g" ); id=$( echo "$id_and_ac" | awk -F"\t" "{print \$1}"); echo -e "$id\t$ac"'
