#!/bin/bash

# find text in a list of date fields in a TSV that are not valid dates and replace with blanks
# args: 1) TSV to get dates from, 2) double quoted list of fields by number to search for dates in
# output is input TSV row ID field (assumed to be first) and input date fields, but with blanks where were invalid
# NB: dates are assumed to be dd/mm/yyyy
# NB: once found, will delete offending dates in any field - this is dangerous, and should be for date fields only

invalid_dates_byField()
{
	sed '1d' |\
	sed 's:^\([0-9]\+\)/\([0-9]\+\)/\([0-9]\+\):\3-\2-\1:g' |\
	grep -vE "^$" |\
	sort |\
	uniq |\
	parallel --gnu 'invaliddate=$( date -d{} 2>&1 1>/dev/null ); if [[ -n $invaliddate ]]; then echo {} ; fi '
}

bad_dates=$(
	for field in $2
	do
		invalid_dates=$( cat $1 | awk -F'\t' "{print \$$field }" | invalid_dates_byField )
		if [[ -n $invalid_dates ]]; then
			echo "$invalid_dates"
		fi
	done 
)

to_ddmmyyyy=$(
	echo "$bad_dates" |\
	while read date
	do
		echo "$date" |\
		sed 's:^\([0-9]\+\)-\([0-9]\+\)-\([0-9]\+\):\3\/\2\/\1:g'
	done
)

for_sed=$(
	echo "$to_ddmmyyyy" |\
	tr '\n' '|' |\
	sed 's:|$::g' |\
	sed 's:\/:\\/:g' |\
	sed 's:|:\\|:g' 
)

cat $1 | sed "s:$for_sed::g"
