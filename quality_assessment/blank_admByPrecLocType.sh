#!/bin/bash
# this is specific to nepal right now
# add user args for prec code, loc type, and adm level ids/names

cat NPL_geocoded_projectLocations.csv | sed '1d' mawk -F"\t" '{OFS="\t";if($3 ~ /^2$/ && $8 ~ /^third-order administrative division$/){$16="";$15=""};if($3 ~ /^3$/){$16="";$15="";$14="";$13=""};if($3 ~ /^4$/){$16="";$15="";$14="";$13="";$12="";$11=""};if($3 > 4 ){$16="";$15="";$14="";$13="";$12="";$11="";$10="";$9=""};print $0}'
