#!/bin/bash

# bows.sh
# make a bag of words using input text
# NB: the bag of words is lowercase, divided by spaces, hypens and forward slashes, whitespace is uniform, converted to ASCII, without newline/return/tab, HTML decoded twice, html2text, punctuation removed
# user args: 1) input text, 2) list of stopwords, one per line, 3) max length of any term
# example: ./bow.sh in.csv stopwords.txt 3

intxt=$1
stopwords=$2
length=$3
# make function to decode HTML
function html_decode { perl -Mutf8 -CS -MHTML::Entities -ne 'print decode_entities($_)'; }
bow=$(  
	cat $intxt |\
	# decode HTML twice - seriously CRS makes this necessary
	html_decode |\
	html_decode |\
	# remove HTML tags
	html2text |\
	# treat hyphens, forward slashes, apostraphes, and underscores as word separators
	tr "-" " " |\
	tr "/" " " |\
	tr "'" " " |\
	tr "_" " " |\
	# remove punctuation
	tr -d "[:punct:]" |\
	# transliterate to ASCII - drop tricky characters
	iconv -c -f UTF8 -t ASCII//TRANSLIT |\
	# take just alpha
	grep -oE "[A-Za-z]+"|\
	# all as lowercase
	tr [:upper:] [:lower:] |\
	# make all whitespace single spaces
	sed "s:[ \t]\+: :g" |\
	# get unique terms
	tr " " "\n" |\
	sort |\
	uniq |\
	# remove leading and trailing whitespace
	sed "s:^ \+::g;s: \+$::g"|\
	# remove blank lines
	grep -vE "^$" |\
	# terms must be at least user supplied length
	awk "{ if ( length(\$0) > $length ) print \$0 }"
)
# remove stopwords
bow=$( grep -vFxf $stopwords <(echo "$bow" ) )
echo "$bow"
