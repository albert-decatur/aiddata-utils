#!/bin/bash

# assign IATI codes to donor agencies, and keep pipe separated lists of IATI codes and donor agencies in step with each other, while keeping donopr agencies with IATI codes at the front of the list
# args: 1) input TSV, 2) three column TSV of IATI org names, IATI code, and ISO3, 3) field in TSV with donors, dash separated
# NB: output assumes first field in input TSV is unique ID

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
	hasIATI_iatiCodes=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$2}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	hasIATI_iso3s=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$3}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	hasIATI_orgName=$( echo "$joined" | awk -F"\t" "{if(\$2 !~ /^$/)print \$1}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	notIATI_iso3s=$( echo "$joined" | awk -F"\t" "{if(\$2 ~ /^$/)print \$3}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	notIATI_orgName=$( echo "$joined" | awk -F"\t" "{if(\$2 ~ /^$/)print \$1}" | tr "\n" "|" | sed "s:|$::g;s:$:\n:g" )
	cat_orgName=$( echo -e "$hasIATI_orgName|$notIATI_orgName" | sed "s:|$::g;s:^|::g" )
	cat_iatiCodes=$( echo -e "$hasIATI_iatiCodes|$notIATI_iatiCodes" | sed "s:|$::g;s:^|::g" )
	cat_iso3s=$( echo -e "$hasIATI_iso3s|$notIATI_iso3s" | sed "s:|$::g;s:^|::g" )
	echo -e "$id\t$cat_orgName\t$cat_iatiCodes\t$cat_iso3s"
'
