#!/bin/bash

# find null deflator country/years given TSV and first and last financial fields
# NB: 
	# assumes financial fields are continguous
	# assumes the null value for deflation is the word 'null'
	# assumes financial field names take the form '[^_]+_[0-9]{4}'

incsv=$1
firstFinancial=$2
lastFinancial=$3
iso3_field=$4

cat $incsv |\
sed '1d' |\
parallel --gnu '
	if [[ -n $(echo {} | grep null ) ]]; then 
		iso3=$( echo {} | awk -F"\t" "{print \$'$iso3_field'}" )
		for field in $( seq '$firstFinancial' '$lastFinancial' )
		do 
			has_null=$(echo {} | awk -F"\t" "{print \$$field}" | grep null )
			if [[ -n $has_null ]]; then 
				yr=$( cat '$incsv' | sed -n "1p" | tr "\t" "\n" | nl | sed "s:^[ \t]\+::g" | grep -E "^\b$field\b" | awk "{print \$2}" | grep -oE "[0-9]+" )
				echo -e "$iso3\t$yr"
			fi
		done
	fi
' |\
sort|\
uniq -c |\
sort -k1 -rn
