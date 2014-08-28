#!/bin/bash

# sentence by sentence comparison of two directories of HTML files using tre-agrep
# outputs a pipe delimited file showing the two sentences, their sources, and the differences between them
# TODO: generalize to any two directories of text files
# prereqs: tre-agrep

outtxt=~/Downloads/factivaAlts.txt
rm $outtxt
echo "numCharText|numCharMatch|meanChar|factivaSource|numCharFactivaSource|hit|cost|meanCharPerCost|factivaText|matchedText" > $outtxt
errors=5
desiredCharPerCost=15
china_factiva=../china_factiva
china_factivaLike_alts=.

for factivaID in $(find $china_factivaLike_alts -regex "[.]/[0-9]+")
do 
	count=$(ls $factivaID|grep -vE "url[.]csv$"|wc -l)
	if [[ $count == 0 ]]; then 
		false
	else 
		find $factivaID -regex "[.]/[0-9]+" -type d | while read sourceID
		do 
			factiva=$china_factiva/$sourceID/${sourceID}.html
			tr '\n' ' ' < $factiva > /tmp/singleLineFactiva.hmtl
			factivaClean=$(echo $factiva | grep -oE "[0-9]+[.]html$"|sed 's:[.]html$::g')
			find $sourceID -regex "[.]/[0-9]+/[0-9]+" -type d | while read hit
			do 
				hitClean=$(echo $hit | grep -oE "[0-9]+$")
				tr '\n' ' ' < $(ls $hit/*) | sed 's:|::g' > /tmp/del.html
				singleLineFactivaBody=$(grep "<p class=\"articleParagraph enarticleParagraph\">" /tmp/singleLineFactiva.hmtl | grep -oE "<p class=\"articleParagraph enarticleParagraph\">.*<p class=\"articleParagraph enarticleParagraph\">" | sed 's:<[^>]*::g
				s:>::g' | sed 's:\([A-Za-z0-9][.]\):\1\n:g' | sed '/^[ \t]\+$/d')
				numCharFactivaSource=$(echo "$singleLineFactivaBody" | wc -c)
				echo "$singleLineFactivaBody" | while read text
				do 
					tre=$(tre-agrep -e "$text" -s -w -k --show-position -E $errors /tmp/del.html)
					if [[ -n ${tre} ]]; then 
						showRange=$(echo "$tre" | grep -oE "^[0-9]+:[0-9]+[-][0-9]+:" | sed 's:^[0-9]\+\:::g
						s:\:::g')
						cost=$(echo "$tre" | grep -oE "^[0-9]+:[0-9]+[-][0-9]+:" | sed 's:^\([0-9]\+\).*:\1:g')
						firstNum=$(echo $showRange | awk -F"-" '{print $1}')
						secondNum=$(echo $showRange | awk -F"-" '{print $2}')
						newFirst=$(echo "$firstNum + 1"|bc)
						newSecond=$(echo "$secondNum + 1"|bc)
						characterRange=${newFirst}-${newSecond}
						matchLine=$(echo "$tre" | sed 's:^[0-9]\+\:[0-9]\+[-][0-9]\+\:::g')
						match=$(echo "$matchLine" | cut -c $characterRange)
						numCharText=$(echo "$text" | wc -c)
						numCharMatch=$(echo "$match" | wc -c)
						meanChar=$(echo "scale=2
						($numCharText + $numCharMatch) / 2"|bc)
						if [[ $cost -le 0 ]]; then 
							echo "$numCharText|$numCharMatch|$meanChar|$factivaClean|$numCharFactivaSource|$hitClean|$cost|9999|$text|$match" >> $outtxt
						else 
							meanCharPerCost=$(echo "scale=2
							$meanChar / $cost" |bc)
						if [[ $(echo "$desiredCharPerCost <= $meanCharPerCost" | bc -l) -eq 1 ]]; then 
							echo "$numCharText|$numCharMatch|$meanChar|$factivaClean|$numCharFactivaSource|$hitClean|$cost|$meanCharPerCost|$text|$match" >> $outtxt
						fi
						fi
					fi
				done
			done
		done
	fi
done
