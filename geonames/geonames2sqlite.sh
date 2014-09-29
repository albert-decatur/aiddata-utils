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
        name VARCHAR(2500) NOT NULL, 
        asciiname VARCHAR(2500) NOT NULL, 
        alternatenames VARCHAR(2500), 
        latitude FLOAT NOT NULL, 
        longitude FLOAT NOT NULL, 
        featureclass VARCHAR(2500) NOT NULL, 
        featurecode VARCHAR(2500) NOT NULL, 
        countrycode TIME NOT NULL, 
        cc2 VARCHAR(2500), 
        admin1code VARCHAR(2500) NOT NULL, 
        admin2code VARCHAR(2500), 
        admin3code VARCHAR(2500), 
        admin4code VARCHAR(2500), 
        population INTEGER NOT NULL, 
        elevation VARCHAR(2500), 
        dem INTEGER NOT NULL, 
        timezone VARCHAR(2500) NOT NULL, 
        modificationdate DATE NOT NULL
);
.separator '	'
.import $geonames $table
CREATE INDEX geoid ON geonames (geonameid);
EOF
# would have used 'cat | sqlite3 $db' but hangs
cat $tmp | sqlite3 $db
