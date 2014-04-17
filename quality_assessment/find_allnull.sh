#!/bin/bash

# given a TSV, a list of fields, and a null value to search for,
# return fields by number that have no non-null values

intsv=$1
field_list=$2
echo "$field_list" |\
tr ' ' '\n'|\
parallel --gnu 'non_null=$( cat '$intsv' | awk -F"\t" "{print \$'{}'}" | sed "1d" | grep -vE "^$" | grep -vE "^'$3'$" | wc -l ); if [[ "$non_null" -eq 0 ]]; then echo {}; fi'
