#!/bin/bash

# put geonames into a sqlite db for fast selects
# user args: 1) geonames txt
# NB: output sqlite is named based on geonames and is overwritten
# NB: this does not use spatialite!

geonames=$1
db=$( basename $geonames .txt ).sqlite
table=geonames
rm $db 2>/dev/null
tmp=$(mktemp)

cat > $tmp <<EOF
CREATE TABLE $table (
        geonameid INTEGER NOT NULL, 
        name TEXT NOT NULL, 
        asciiname TEXT NOT NULL, 
        alternatenames TEXT, 
        latitude REAL NOT NULL, 
        longitude REAL NOT NULL, 
        featureclass TEXT NOT NULL, 
        featurecode TEXT NOT NULL, 
        countrycode TIME NOT NULL, 
        cc2 TEXT, 
        admin1code TEXT NOT NULL, 
        admin2code TEXT, 
        admin3code TEXT, 
        admin4code TEXT, 
        population INTEGER NOT NULL, 
        elevation TEXT, 
        dem INTEGER NOT NULL, 
        timezone TEXT NOT NULL, 
        modificationdate DATE NOT NULL
);
.separator '	'
.import $geonames $table
CREATE INDEX geoid ON geonames (geonameid);
EOF
# would have used 'cat | sqlite3 $db' but hangs
cat $tmp | sqlite3 $db
