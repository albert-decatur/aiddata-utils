#!/bin/bash

# tf-idf from postgres db
# user args: postgres db where the column 'description' from the table 'projects' contains docs for tf-idf
# prereqs: 1) Stanford NER running on localhost:2020, 2) wordnet


db=$1

echo "copy (select distinct(id) from projects) to stdout;" |\
psql -d $db |\

while read project
do 
	terms=$(echo "copy (select distinct(description) from projects\
	where description is not null and id = '$project') to stdout" | psql -d $db |\
	nc localhost 2020 | tr ' ' '\n' |\
	grep -oE ".*_(NN|NNS|POS|VB|VBD|VBG|VBN|VBP|VBZ)$" |\
	sed 's:_\(NN\|NNS\|POS\|VB\|VBD\|VBG\|VBN\|VBP\|VBZ\)$::g' |\
	tr '\n' ' ' | awk '{print tolower($0)}' |\
	perl -lne "{ s/[^[:ascii:]]+//g; print; }" |\
	perl -lne "{ s/[^a-zA-Z]+/ /g; print; }" |\
	sed 's:[ ]:\n:g' | sort | uniq -c  |\
	awk '{ if( $2 != "" && length($2) > 2 ) print $0 }' |\
	sort -k1 -rn |\
	while read line
	do 
		term=$(echo $line | awk '{print $2}')
		f=$(echo $line | awk '{print $1}')
		if [[ $(wordnet $term -grepn | wc -l) -gt 1 ]]; then
			echo "$term $f"
		fi; 
	done) 

	mtf=$(echo "$terms" | sed -n '1p' | awk '{print $2}')
	atf=$(echo "$terms" | awk "{print  0.5 + ( \$2 * 0.5 / ( $mtf ) ),\$1  }")
	echo "$atf" > ${project}.atf
done

idfFile=corpus.idf
rm $idfFile 2>/dev/null
D=$(ls *.atf | wc -l)
awk '{print $2}' * | sort | uniq |\

while read t
do 
	d=$(grep -E "\b$t\b" *.atf | wc -l)
	idf=$(echo "scale=10; l( $D / ( 1 + $d ) )/l(10)" | bc -l)
	echo "$t $idf" >> $idfFile
done
