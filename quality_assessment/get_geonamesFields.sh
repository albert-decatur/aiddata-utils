#!/bin/bash

# args: 1) TSV, 2) geonameID field number in TSV, 3) geonames username
# output is TSV of geonameID,lat,lng,fcodeName,admCodes,admNames,time retrieved from API (UTC seconds)


# print header
echo -e "geonameID\tplacename\tlatitude\tlongitude\tlocation_type\tgeonames_ADMcode\tgeonames_ADMname\tgeonamesAPI_retrievalTime"

cat $1|\
# remove header
sed '1d'|\
# print GeoNameID field
awk -F"\t" "{print \$${2}}"|\
sort|\
# get unique list of GeoNameIDs
uniq|\
# for every geonameID return desired elements from geonames API
parallel --gnu '
	# get all the elements from the API we want later
	elements=$( 
		curl -s "http://api.geonames.org/get?geonameId={}&username='$3'" |\
		grep -E "<countryCode>[^<]*</countryCode>|<countryName>[^<]*</countryName>|<name>[^<]*</name>|<lat>[^<]*</lat>|<lng>[^<]*</lng>|<fcodeName>[^<]*</fcodeName>|<admin" 
	)
	# get the current time in seconds UTC
	time=$( date -u --iso-8601=seconds )
	# get pipe separated list of both ADM codes and ADM names
	country_code=$( echo "$elements" | grep -E "<countryCode>[^<]*</countryCode>" | grep -oE ">[^<]*<" | sed "s:>\|<::g")
	country_name=$( echo "$elements" | grep -E "<countryName>[^<]*</countryName>" | grep -oE ">[^<]*<" | sed "s:>\|<::g")
	admFields=$( echo "$elements" | grep -E "<admin" )
	admCodes=$( echo "$admFields" | grep "^<adminCode" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	admNames=$( echo "$admFields" | grep "^<adminName" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	admCode=$( echo "$admCodes" | sed "s:|::g" | tr "\n" "|" | sed "s:|$::g" | sed "s:^:$country_code|:g" )
	admName=$( echo "$admNames" | sed "s:|::g" | tr "\n" "|" | sed "s:|$::g" | sed "s:^:$country_name|:g" )
	# get other elements
	lat=$( echo "$elements" | grep -E "<lat>[^<]*</lat>" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	lng=$( echo "$elements" | grep -E "<lng>[^<]*</lng>" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	name=$( echo "$elements" | grep -E "<name>[^<]*</name>" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	fcodeName=$( echo "$elements" | grep -E "<fcodeName>[^<]*</fcodeName>" | grep -oE ">[^<]*<" | sed "s:>\|<::g" )
	echo -e "{}\t$name\t$lat\t$lng\t$fcodeName\t$admCode\t$admName\t$time"
'
