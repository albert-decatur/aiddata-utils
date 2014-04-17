#!/bin/bash

# convert AD3 IATI XML to JSON for filtering by jq
# prereqs: xml2json, GNU parallel
# args: 1) input directory with AD3 IATI XML

# example use to get iati identifiers by piping to jq: 
# $0 . | jq '.iati_activities.iati_activity[]|.iati_identifier'

indir=$1

# disgusting apostraphe variable for GNU parallel for jq
a="'"
# find XML files under current directory - should just be IATI XML from AD3
find $indir -type f -iregex ".*[.]xml$" |\
# for every XML file, convert to JSON and pull out iati-identifiers
parallel --gnu '
        xml2json -t xml2json {} |\
        jq '$a'.'$a' |\
        sed "s:-:_:g"
'
