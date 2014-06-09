#!/bin/bash

# find location type / precision code combinations that are not allowable in an input TSV according to an input spreadsheet of allowable combos
# allowable combos TSV has to have this structure: first col is location type, remaning cols are allowable precision codes for that location type
# user args: 1) input TSV to check, 2) input TSV precision code field number, 3) input TSV location type field number, 4) TSV of allowable precision codes
# example use: $0 foo.tsv 28 29 allowableCombos.tsv

intsv=$1
in_precCodeField=$2
in_locTypeField=$3
acceptLocPrec=$4

# header
echo -e "precCode\tLocType"

cat $intsv |\
# remove header
sed '1d'|\
awk -F'\t' "{OFS=\"\t\"; print \$$in_precCodeField,\$$in_locTypeField}" |\
# only use unique combinations to speed up
sort|\
uniq|\
parallel --gnu '
	in_prec=$( echo {} | awk -F"\t" "{OFS=\"\t\";print \$1}" )
	in_loc=$( echo {} | awk -F"\t" "{OFS=\"\t\";print \$2}" | sed "s:(\|)::g")
	in_prec_is_good=$( cat '$acceptLocPrec' | sed "1d" | sed "s:(\|)::g" | awk -F"\t" "{OFS="\t";if(\$1 ~ /^${in_loc}$/)print \$0}" | awk -F"\t" "{\$1=\"\";print \$0}" | sed "s:^[ \t]\+::g" | tr " " "\n" | grep -vE "^$" | while read prec; do echo $prec; done | grep "$in_prec" | grep -vE "^$" | wc -l )
	if [[ "$in_prec_is_good" -gt 0 ]]; then 
		false
	else 
		echo -e "$in_prec\t$in_loc"
	fi
'
