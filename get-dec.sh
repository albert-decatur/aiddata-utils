#!/bin/bash

# user args: 1) input csv with DEC metadata, 2) dir to put dec pdfs in by yr
# relies on metadata CSVs from https://github.com/USAID/USAID-DEC

csv=$1
decdir=$2
# get year from CSV name
yr=$(echo $csv | grep -oE "[0-9]+")
# make folder for that year
mkdir -p $decdir/$yr/ 2>/dev/null
# print the CSV, grab the doc ID column, and download from the URL that uses that ID
# save in the year's folder
cat $csv |\
sed '1d'|\
csvquote |\
awk -F, '{print $35}' |\
sed 's:"::g;s:-::g;s:$:.pdf:g'|\
parallel --gnu 'wget -cP '$decdir'/'$yr'/ http://pdf.usaid.gov/pdf_docs/{}'
