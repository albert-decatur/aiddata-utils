#!/bin/bash

# find text in a TSV that looks like a dd/mm/yyyy date and replace with a blank if it is invalid
# args: 1) TSV to get dates from
# output is stdout
# NB: works on all strings that match the regex \b[0-9]+/[0-9]+/[0-9]+\b

invalid_dates_any()
{
	to_blank=$(
	cat $1 |\
	grep -oE "\b[0-9]+/[0-9]+/[0-9]+\b" |\
	sed 's:^\([0-9]\+\)/\([0-9]\+\)/\([0-9]\+\):\3-\2-\1:g' |\
	grep -vE "^$" |\
	sort |\
	uniq |\
	parallel --gnu 'invaliddate=$( date -d{} 2>&1 1>/dev/null | grep -oE "[0-9-]+" | sed "s:^\([0-9]\+\)-\([0-9]\+\)-\([0-9]\+\):\3/\2/\1:g" ); if [[ -n $invaliddate ]]; then echo "$invaliddate"; fi ' |\
	sort |\
	uniq |\
	tr '\n' '|' |\
	sed 's:|$::g;s:|:\\|:g' 
	)

}

blank_invalid_dates()
{
	cat $1 | sed "s:$to_blank:\t:g"
}

invalid_dates_any $1
blank_invalid_dates $1
