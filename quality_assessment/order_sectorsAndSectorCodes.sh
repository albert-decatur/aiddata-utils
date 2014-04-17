#!/bin/bash

# assign aiddata sector codes to AMP sectors, and keep pipe separated lists of sectors and their codes in step with each other, keeping sectors with codes at the front of the list
# args: 1) input TSV, 2) three column TSV of sector names, sector codes, and aiddata sector names, 3) field in TSV with sectors, dash separated
# NB: output assumes first field in input TSV is unique ID
# NB: code adapted from similar task for IATI codes

cat $1 |\
# remove header
sed '1d' |\
parallel --gnu '
	id=$( echo {} | awk -F"\t" "{print \$1}" )
	donorList=$( echo {} | awk -F"\t" "{print \$'$3'}" | tr "-" "\n" | sed "s:^[ \t]\+::g;s:[ \t]\+$::g" | sort | uniq | grep -vE "^$" )
	tmp=$( mktemp )
	echo "donor_agency" > $tmp
	joined=$( echo "$donorList" >> $tmp
	csvjoin -t -c1,1 $tmp '$2' |\
	sed "1d" |\
	csvquote |\
	sed "s:\t::g;s:,:\t:g" |\
	awk -F"\t" "{OFS=\"\t\";print \$2,\$3,\$4}" )
	hasADSECTOR_sectorCodes=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$2}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	hasADSECTOR_iso3s=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$3}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	hasADSECTOR_orgName=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$1}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	notADSECTOR_iso3s=$( echo "$joined" | awk -F"\t" "{if(\$2 ~ /^$/)print \$3}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	notADSECTOR_orgName=$( echo "$joined" | awk -F"\t" "{if(\$2 ~ /^$/)print \$1}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	cat_orgName=$( echo -e "$hasADSECTOR_orgName|$notADSECTOR_orgName" | sed "s:|$::g;s:^|::g" )
	cat_sectorCodes=$( echo -e "$hasADSECTOR_sectorCodes|$notADSECTOR_sectorCodes" | sed "s:|$::g;s:^|::g" )
	cat_iso3s=$( echo -e "$hasADSECTOR_iso3s|$notADSECTOR_iso3s" | sed "s:|$::g;s:^|::g" )
	echo -e "$id\t$cat_orgName\t$cat_sectorCodes\t$cat_iso3s"
'
