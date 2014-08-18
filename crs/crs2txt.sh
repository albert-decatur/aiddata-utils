#!/bin/bash

# convert DAC's multiple UTF-16 CRS txt files to a single pipe delimited UTF-8 txt file
# NB: assumes that all CRS txt files use the same headers.  they better!  also all files in input dir must be CRS input UTF-16 txt files
# these DAC txt dumps can be found [here](http://stats.oecd.org/DownloadFiles.aspx?HideTopMenu=yes&DatasetCode=CRS1)
# user args: 1) dir with CRS txt, 2) output name of single txt file

# example use $0 2014-06-16/ crs_2012-06-16.txt

headersource=$(
find $1 -type f |\
sed -n '1p'
)

tmpdir=$(mktemp -d)

for i in $( find $1 -type f )
do 
	cp $i $tmpdir
	cd $tmpdir
	# convert from utf-16 to utf-8
	iconv -f utf16 -t utf8 $( basename $i )|\
	# remove UTF-16 BOM
	awk '{ sub(/^\xef\xbb\xbf/,""); print }' |\
	# remove null character
	tr -d '\000' |\
	sponge $( basename $i )
	cd -
done

# dump header into output file
head -n 1 $tmpdir/$( basename $headersource ) > $2

# append non-header records to output file
for i in $( find $tmpdir -type f )
do 
	cat $tmpdir/$( basename $i ) | sed '1d' >> $2
done
