#!/bin/bash

# NB: must remove newlines and tabs from xls *first* before you can use this script

# convert xls(x) to TSV, optionally using start and end columns (eg to get just financials from AMP, or no financials)
# user args: 1) input xls(x), 2) start column by number, 3) end column by number
# NB: if the number of args is 3, use first and last cols, if number is any other, show all cols
# prereq: gnumeric's ssconvert

inxls=$1
startcol=$2
endcol=$3

if [[ $# -eq 3 ]]; then
	awkcols=$( seq $startcol $endcol | sed 's:^:$:g' | tr '\n' ',' | sed 's:,$::g' )
	ssconvert --export-type Gnumeric_stf:stf_assistant -O 'separator="	"' $inxls fd://1 | awk -F "\t" "{OFS=\"\t\";print $awkcols}"
else
	ssconvert --export-type Gnumeric_stf:stf_assistant -O 'separator="	"' $inxls fd://1 
fi
