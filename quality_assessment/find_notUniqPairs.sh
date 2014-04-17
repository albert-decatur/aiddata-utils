#!/bin/bash

# args: 1) input TSV, 2) first field, 3) second field
# output: count of, and field values when pairs are not unique

cat $1 |\
sed '1d'|\
awk -F "\t" "{OFS=\"\t\";print \$${2},\$${3}}" |\
sort |\
uniq -c |\
sort -k1 -rn |\
# make a TSV from counts of unique pairs of values of the fields
sed "s:^[ \t]\+::g;s:[ \t]\+$::g;s:^\([0-9]\+\) :\1\t:g" |\
awk -F"\t" "{OFS=\"\t\";if(\$1 > 1)print \$0}"
