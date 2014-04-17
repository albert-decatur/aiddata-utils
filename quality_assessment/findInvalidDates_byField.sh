#!/bin/bash

# find text in a list of date fields in a TSV that are not valid dates and replace with blanks
# args: 1) TSV to get dates from, 2) double quoted list of fields by number to search for dates in
# output is a two column TSV to stdout with 1) field name, 2) invalid date value
# NB: dates are assumed to be dd/mm/yyyy

invalid_dates_byField()
{
	sed '1d' |\
	sed 's:^\([0-9]\+\)/\([0-9]\+\)/\([0-9]\+\):\3-\2-\1:g' |\
	grep -vE "^$" |\
	sort |\
	uniq |\
	parallel --gnu 'invaliddate=$( date -d{} 2>&1 1>/dev/null ); if [[ -n $invaliddate ]]; then echo {} ; fi '
}

echo -e "field_name\tinvalid_date"
for field in $2
do
	invalid_dates=$( cat $1 | awk -F'\t' "{print \$$field }" | invalid_dates_byField )
	if [[ -n $invalid_dates ]]; then
		num_repeat=$( echo "$invalid_dates" | wc -l )
		field_name=$(cat $1 | awk -F"\t" "{print \$$field}" | sed -n "1p")
		field_repeat=$( yes $field_name | head -n $num_repeat )
		paste -d'\t' <( echo "$field_repeat" ) <( echo "$invalid_dates" )
	fi
done
