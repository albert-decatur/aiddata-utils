#!/bin/bash
# needs tons of work - should be able to go to years *after* base year as well as before
# inputs are very strict right now
# args: 1) input TSV of GDP inflation by country/year, from base year on
# example use: ./$0 np_missing_deflators_GDPinflation.csv

base_yr=2011
start_gdpi=100
incsv=$1
cat $incsv | sed '1d' | parallel --gnu 'iso3=$( echo {} | awk -F"\t" "{print \$1}" ); i=1; gdpi=( ); echo {} | awk -F"\t" "{OFS=\"\t\";\$1=\"\";print \$0}" | tr "\t" "\n" | sed "1d" | while read inflation; do if [[ $i -eq 1 ]]; then echo -e "$iso3\t'$base_yr'\t100"; previous_gdpi='$start_gdpi'; i=$((i+1)); else array_position=$(echo "${#gdpi[@]}-1" | bc ); previous_gdpi=$( echo "${gdpi[$array_position]}" ); fi; new_gdpi=$( echo "scale=15; $previous_gdpi / ( 1 + ( $inflation / 100 ) )" | bc ); gdpi+=($new_gdpi); gdpi=$( echo "scale=15; $previous_gdpi / ( 1 + ( $inflation / 100 ) )" | bc ); if [[ -n $array_position ]]; then col_num=$( echo "$array_position + 2" | bc ); yr_plus_one=$( cat '$incsv' | awk -F"\t" "{print \$${col_num}}" | sed -n "1p" | grep -oE "[0-9]+" ); yr=$( echo "$yr_plus_one - 1" | bc ); else yr=$( echo "'$base_yr' - 1" | bc); fi; echo -e "$iso3\t$yr\t$gdpi"; done'
