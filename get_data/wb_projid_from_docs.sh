#!/bin/bash

# for a given World Bank project, find instances of World Bank project IDs mentioned in its docs 
# that are not its own project ID
# example use: $0 P102792

projid=$1
curl -s "http://search.worldbank.org/api/v2/wds?format=json&proid=$projid&srt=docdt&order=desc" |\
jq '.documents[]|.txturl|@text' |\
grep -vE '^"null"$' |\
parallel --gnu '
	echo curl -s {} |\
	sh |\
	grep -E "P[0-9]{6}" |\
	grep -vE "\b'$projid'\b"
'
