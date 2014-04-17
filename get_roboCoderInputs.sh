#!/bin/bash

usage()
{
cat << EOF
usage: $0 [OPTIONS]

Make TSV inputs for AidData's RoboCoder:

Get n random records from AidData2.2 research release Postgres DB.
Can query by code rule length, and/or a donor regexp and/or a sector regexp.
Postgres' matches case-insensitive operator is used for regexp ('~*');
For example, get 500 random records where World Bank was the donor, or 1000 random records with a code rule length >20 characters and <=100 characters. 
NB: "code rule" means the title, short_description, and long_description fields.

OPTIONS:
   -h      show this message
   -p      Postgres DB with AidData 2.2 (required)
   -c      code rule character length range as two double quoted numbers. NB: min is inclusive, max is not.
   -d      donor regexp
   -s      sector regexp
   -n      number of random records to return (required)

Example: $0 -p aiddata22 -n 1000 -c "1 200" -d "United States|Slovenia" -s "III.1.b. Forestry"
Example: $0 -p aiddata22 -n 1000 -s "III.1.b. Forestry|III.3.b. Tourism"

EOF
}

while getopts "hp:c:d:s:n:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
             db=$OPTARG
             ;;
         c)
             characterRange=($OPTARG)
             ;;
         d)
             donor_regex=$OPTARG
             ;;
         s)
             sector_regex=$OPTARG
             ;;
         n)
             n=$OPTARG
             ;;
     esac
done

# quit if -p and -n flags are not both in use
if [[ -z $db || -z $n ]]; then
	echo "Please select a Postgres DB with AidData2.2 and the number of records to return."
	exit 1
fi

# define code rule character length range
min=${characterRange[0]}
max=${characterRange[1]}

# if donor, sector, or characterRange flags are used then those lines of SQL are provided, if not they are blank 
if [[ -n $characterRange ]]; then
	lengthsql="and length >= $min and length < $max"
fi
if [[ -n $donor_regex ]]; then
	donorsql="and donor ~* '$donor_regex'"
fi
if [[ -n $sector_regex ]]; then
	sectorsql="and sector ~* '$sector_regex'"
fi

# make a tmp file for SQL query
sql=$(mktemp)

cat > $sql << EOF
	copy ( 
		with tmp as ( 
			select 
			aiddata_id
			,donor
			,recipient
			,sector
			,title
			,short_description
			,long_description
			,aiddata_activity_code
			,length(concat(title,short_description,long_description)) as length 
			from aiddata2_2_provisional 
		)  
		select * from tmp 
		where aiddata_activity_code is not null 
		and (title is not null OR short_description is not null OR long_description is not null ) 
		-- if the flags for these are used then a line of SQL appears, else they are blank
		$lengthsql
		$donorsql
		$sectorsql
		order by random() 
		limit $n 
	) 
	to stdout 
	with delimiter E'\t' 
	csv header
EOF

# preferred to just 'cat | psql $db << EOF' but was hanging at end
cat $sql | psql $db
