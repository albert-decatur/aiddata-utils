#!/bin/bash

# deflate comms and disburs by project ID, using ISO3, year, and deflation TSV

# args: 
# 1) input comms and disburs fields, with project ID at front, 
# 2) first input comm/disburs field number
# 3) last input comm/disburs field number
# 4) input comm/disburs ISO3 field number
# 5) deflation TSV, with the following fields: year, donor ISO3 (DAC for multidonor), deflator value
# NB: comms and disburs fields expected to look like this: "c_2003" or "d_2011"  
# NB: first field of financial csv assumed to be ID field
# example ./$0 nepal_CommDisburs.csv 15 41 4 deflate_to_usd2011.csv

# TODO: remove hardcoded field position values

financial_csv=$1
deflate_csv=$5
deflator_iso3_field=4
deflator_yr_field=1
deflator_field=2

# range of fields that have financials in $financial_csv
begin_field=$2
end_field=$3

# iso3 field in $financial_csv
iso3_field=$4

# print the project ID header and the headers of all fields inside the range of fields between $begin_field and $end_field
out_header=$( 
	cat $financial_csv |\
	sed -n '1p' |\
	tr '\t' '\n' |\
	nl |\
	sed 's:^[ \t]\+::g' |\
	grep -E "^\b(1|$( seq $begin_field $end_field | tr '\n' '|' | sed 's:|$::g'))\b" |\
	awk '{$1="";print $0}' |\
	tr '\n' '\t'
)
echo "$out_header"

cat $financial_csv |\
# ignore header
sed '1d' |\
# for every line in $financial_csv, choose the appropriate deflator from $deflator_csv according to ISO3 and year, and do this:
# currentUSD / deflator * 100
# report project ID, deflated values for the row
parallel --gnu '
	id=$( echo {} | awk -F"\t" "{print \$1}" )
	iso3=$( echo {} | awk -F"\t" "{print \$'$iso3_field'}" )
	for fieldNum in $( seq '$begin_field' '$end_field')
	do 
		currentUSD=$( echo {} | awk -F"\t" "{print \$$fieldNum}" )
		yr=$( cat '$financial_csv' | sed -n "1p" | awk -F"\t" "{print \$$fieldNum}" | grep -oE "[0-9]+" )
		if [[ $( echo "$currentUSD == 0" | bc ) -eq 1 ]]; then 
			echo -e "$currentUSD"
		else  
			deflator=$( cat '$deflate_csv' | awk -F"\t" "{if( \$'$deflator_iso3_field' ~ /^$iso3$/ && \$'$deflator_yr_field' ~ /^$yr$/)print \$'$deflator_field'}" )
			deflator_count=$( echo "$deflator" | grep -vE "^$" | wc -l )
			if [[ $deflator_count -eq 0 ]]; then 
				echo "null"
			else 
				USD2011=$( echo "scale=4; ( $currentUSD / $deflator ) * 100" | bc )
				echo "$USD2011"
			fi
		fi
	done |\
	# report results on a single tab separated line
	tr "\n" "\t" |\
	# place project ID at front, put newline at end
	sed "s:^:$id\t:g;s:$:\n:g"
'
