#!/bin/bash

# make a pipe separated list of activity descriptions in the same order as an input pipe separated activity code column
# using a range of activity description columns, a pipe separated activity *code* column, and a TSV of all AidData's activity codes and their descriptions.
# NB: activity description columns are assumed to be evenly numbered
# args: 1) input TSV with pipe separated activity code column, 2) number of column in input CSV with pipe separated activity codes, 3) TSV of all AidData activity codes and their descriptions, 4) first activity description field number, 5) second activity description field number
# TODO: rarely activity description will be printed one cell below where it should be

incsv=$1
all_codes=$3

# for activity codes found in the input TSV, get a TSV of activity codes and their descriptions 
ac_descriptions=$( 
	cat $incsv |\
	awk -F'\t' "{print \$$2}"|\
	sed '1d'|\
	tr '|' '\n' |\
	sort |\
	uniq|\
	grep -vE "^$"|\
	parallel --gnu 'grep -E "^\b{}\b" '$all_codes' | awk -F"\t" "{OFS=\"\t\";print \$1,\$2}"' |\
	sort -k1 -t'	' -n
)
# save activity codes and their descriptions to a tmp file
echo "$ac_descriptions" > /tmp/ac_descriptions

# for every line of the input TSV, join its activity codes to the appropraite activity description, and make that a pipe separated column 
cat $incsv |\
parallel --gnu 'id=$( echo {} | awk -F"\t" "{print \$1}"); ac=$( echo {} | awk -F"\t" "{print \$'$2'}" ); if [[ -n $ac ]]; then ac_list=$( echo {} | awk -F"\t" "{print \$'$2'}" | tr "|" "\n" | sort -n); join -t"	" /tmp/ac_descriptions <(echo "$ac_list") | awk -F"\t" "{print \$2}" | tr "\n" "|" | sed "s:$:\n:g" | sed "s:|$::g" | sed "s:^:$id\t:g"; else echo -e "$id\t"; fi'
