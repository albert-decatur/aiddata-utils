#!/bin/bash

# make a field by concatenating two fields, separated with an underscore
# args: 1) input TSV, 2) first field in ID, 3) second field in ID, 4) ID field name
# NB: print ID field at front of TSV

# example: make ID field from projectID and geonameID
# ./$0 nepal.csv 1 4 AidData_Nepal_ID

# print header
oldHeader=$( sed -n '1p' $1 )
newHeader=$( echo -e $4"\t$oldHeader" )
echo "$newHeader"

cat $1 |\
# ignore header
sed '1d'|\
# print user selected concatenated fields at front of TSV
awk -F"\t" "{OFS=\"\t\";print \$${2}\"_\"\$${3},\$0}"
