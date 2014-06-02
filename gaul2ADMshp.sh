#!/bin/bash

# make a shapefile for every FAO GAUL administrative district
# this is prep for tilestache 
# user args: 1) GAUL global shapefile

inshp=$1
for n in 1 2
do 
        ogrinfo -geom=no -sql "select ADM${n}_CODE from $(basename $inshp .shp)" $inshp |\
        grep = |\
        grep -oE "[^=]*$" |\
        grep -oE "[0-9]+" |\
        sort |\
        uniq |\
        parallel --gnu '
                ogr2ogr -sql "select * from $( basename '$inshp' .shp ) where ADM'$n'_CODE = '{}'" out/adm'$n'_{}.shp '$inshp' 
        '
done
