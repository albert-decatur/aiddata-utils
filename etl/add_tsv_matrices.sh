#!/bin/bash
# sums two TSV matrices, first strips off headers and first column and then adds them back at the end
# args are two input TSV and the output file
# NB: first column and header must be identical and output will be overwritten
# NB: also overwrite: /tmp/a /tmp/b /tmp/firstCol /tmp/sum

# define temp files to hold matrices withou first column or header for awk to process
matrix_a=/tmp/a
matrix_b=/tmp/b

# save first column minus its header for later
awk -F'\t' '{print $1}' $1 | sed '1d' > /tmp/firstCol

# save header for later
header=$(sed -n '1p' $1)

# make a copy without first column for header for awk to process
awk -F'\t' '{OFS="\t"}{$1="";print $0}' $1 | sed '1d' | sed 's:^[ \t]\+::g;s:[ \t]\+$::g' > $matrix_a
awk -F'\t' '{OFS="\t"}{$1="";print $0}' $2 | sed '1d' | sed 's:^[ \t]\+::g;s:[ \t]\+$::g' > $matrix_b

# use awk to sum matrices - use printf to print real numbers rounded to two decimal places. appends to output that already has header
awk -F'\t' '
FNR==NR {
for(i=1; i<=NF; i++)
_[FNR,i]=$i
next
}
{
for(i=1; i<=NF; i++)
printf("%4.2f%s", $i+_[FNR,i], (i==NF) ? "\n" : FS);
}' $matrix_a $matrix_b > /tmp/sum

# prepare the output with header and first column
echo "$header" > $3

# add first column back to summed output and append these to file that already has header
paste /tmp/firstCol /tmp/sum >> $3
