#!/bin/bash

# args: 1) dir w/ shp, 2) output dir for JSON.  NB: will overwrite

find $1 -type f -iregex ".*[.]shp$" |\
parallel -k --gnu '
json=$(
cat <<EOF
    "$( basename {} .shp )":
    {
        "provider": {"name": "mapnik", "mapfile": "adm_xml/$( basename {} .shp ).xml"}
    },
EOF
)

echo "$json" > '$2'/$( basename {} .shp).json
'
