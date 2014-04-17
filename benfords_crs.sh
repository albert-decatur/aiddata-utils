#!/bin/bash

# TODO switch to mawk
# args: 1) OECD CRS, 2) field number for disbursements
# uses first non zero digit
# handles scientific notation using 'E'
intxt=$1
disburs_field=$2
benfords=('30.1' '17.6' '12.5' '9.7' '7.9' '6.7' '5.8' '5.1' '4.6')                                                                                                                             
countLeadingDigits=$(
	cat $intxt |\
	sed '1d'|\
	awk -F"|" "{if(\$${disburs_field} ~ /E/)printf \"%.40f\n\", \$${disburs_field}; else print \$${disburs_field}}" |\
	grep -oE "^(0|[.])*[^0|.]" | grep -oE "[^0|.]" |\
	sort | uniq -c | sort -k1 -rn | sed "s:^[ \t]\+::g;s:[ \t]\+$::g;s:[ ]:\t:g"
)

sum=$(echo "$countLeadingDigits" | awk -F'\t' '{ sum += $1 } END { print sum }')

i=0
echo "$countLeadingDigits" | while read line
do
        prctFreq=$(echo "$line" | awk -F'\t' "{ OFS="\t"; print \$1 / ${sum} * 100 }")
        prctBenfords=$(echo "$line" | awk -F'\t' "{ print ${prctFreq} / ${benfords[@]:$i:1} }")
        leadingDigit=$(echo "$line" | awk -F'\t' '{print $2}')
        echo -e "${leadingDigit}\t$( printf "%4.2f" ${prctFreq} )\t$( printf "%4.2f" ${prctBenfords} )"
        i=$(($i+1))
done
