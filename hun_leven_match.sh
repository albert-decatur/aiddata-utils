#!/bin/bash

# given aiddata2.1/geonames fuzzy text match, return only records that:
#	1. match if lower case and punctuation are removed
#	2. else match if **both** appear in hunspell english dictionary, or **neither** appear in hunspell english dictionary **and** levenshtein distance is not above user supplied limit
#	3. **and** match_text string meet minimum length
# NB: entirely specific to output from geonames_aiddata21_match.sh
# TODO: take into account whether match is entire word or only part of word.  work in vowels vs consontants, esp. position in word.  soundex?  metaphone?
# user args: 1) input pipe separated file with the fields named 'placename','match_text', etc, 2) allowable levenshtein distance, 3) allowable minimum match_text string length
# example use: $0 xaa 1 4

intxt=$1
levenshtein_allowed=$2
allowed_length=$3
cat $intxt |\
sed 's:\/::g' |\
parallel --gnu --trim n --colsep '\|' --header : '
	function length { echo $1 | tr -d "[:punct:]" | awk "{print length(\$1)}";}
	function comparable { echo $1 | tr -d "[:punct:]" | awk "{print tolower(\$0) }";}
	function hunout { echo $1 | tr -d "[:punct:]" | hunspell -a | sed "1d" | grep -vE "^$" | grep -vE "\*"; }
	function levenshtein { /usr/local/bin/levenshtein.py $1 $2; }
	# NB: because GNU parallel --colsep will not print {} with original delimiters, print just ID fields and use them to find acceptable records later
	function printall { echo {aiddata_id}"|"{geonameid};}

	# if the length of the match_text and the placename are above the allowed length then proceed
	if [[ $( length {match_text} ) -ge '$allowed_length' && $( length {placename} ) -ge '$allowed_length' ]]; then
		if [[ $( comparable {placename} ) != $( comparable {match_text} ) ]]; then 
			hun_match=$( hunout {match_text} )
			hun_place=$( hunout {placename} )
			if [[ ( -n $hun_match && -n $hun_place ) || ( -z hun_match && -z hun_place ) ]]; then 
				# if match_text and placename are both in hunspell or both not in hunspell find levenshtein distance and print if its <= allowed limit
				dist=$( levenshtein {match_text} {placename} )
				if [[ $dist -le '$levenshtein_allowed' ]]; then 
					printall
				fi
			fi
		else 
			# if strings are comparable as lowercase and without punctuation then print everything
			printall
		fi
	fi
'
