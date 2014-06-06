#!/bin/bash

# TODO do not search donor and recipient names

usage()
{
cat << EOF
usage: $0 [OPTIONS]

Prints Geonames and AidData 2.1 matches by project descriptions to stdout. 
Matches include Geonames geonameid,latitude,longitude, and the matched placename, as well as the AidData 2.1 aiddata_id,title,short_description,long_description.
Uses all possible alternate placenames provided by Geonames and allows for the number of typos specified by the user.

OPTIONS:
   -h      show this message
   -e      number of errors to allow in matched text.  Errors include characters substitutions, deletions, and additions.  The pattern to match is the Geonames place names, including alternate names.
   -g      input Geonames using the format for allCountries.txt (uses all the same columns and tab separation)
   -a      input AidData 2.1 columns as pipe separated text: aiddata_id,title,short_description,long_description

Example: $0 -e 1 -g /tmp/geonames_MA.txt -a /tmp/aiddata21_MAR_descriptions.csv

EOF
}

while getopts "he:g:a:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         e)
             errors=$OPTARG
             ;;
         g)
             geonames=$OPTARG
             ;;
         a)
             aiddataDescriptions=$OPTARG
             ;;
     esac
done

echo "geonameid|latitude|longitude|placename|match_text|aiddata_id|title|short_description|long_description"
while read geoline
do 
	altString=$(echo "$geoline" | sed 's:|: :g' | awk -F'\t' '{OFS="|"}{if($4 != "")print $1,$5,$6,$4}')
	if [[ -n "$altString" ]]; then 
		altLatLong=$(echo "$altString" | awk -F"|" '{OFS="|"}{print$2,$3}')
		geonameid=$(echo "$altString" | awk -F"|" '{print $1}')
		echo "$altString" | awk -F"|" '{print $4}' | sed 's:,:\n:g'| sed "s:^:${altLatLong}|:g;s:^:${geonameid}|:g"
		else 
			echo "$geoline" | sed 's:|: :g' | awk -F'\t' '{OFS="|"}{print $1,$5,$6,$2}'
	fi
done < $geonames |\

while read altPlaceNames
do 
	place=$(echo "$altPlaceNames" | awk -F"|" '{print $4}')
	tre-agrep -E $errors -w -e "$place" --show-position $aiddataDescriptions |\
	while read matchline
	do 
		characterRange=$(echo "$matchline" | grep -oE "^*[^:]+" | awk -F"-" "{OFS=\"-\"}{print \$1+1,\$2+1}")
		match=$(echo "$matchline" | sed "s:^[0-9]\+-[0-9]\+\:::g" | cut -c $characterRange)
		body=$(echo "$matchline" | sed 's/^[0-9]\+-[0-9]\+://g')
		echo "$altPlaceNames|$(echo "$match" | sed 's:|::g')|$body"
	done
done
