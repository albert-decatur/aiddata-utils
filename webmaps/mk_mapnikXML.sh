#!/bin/bash

# args: 1) dir w/ shp, 2) dir for output xml

find $1 -type f -iregex ".*[.]shp$" |\
parallel --gnu '
xml=$(
cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE Map[]>
<Map srs="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over" maximum-extent="-20037508.34,-20037508.34,20037508.34,20037508.34">

<Parameters>
  <Parameter name="bounds">-180,-85.05112877980659,180,85.05112877980659</Parameter>
  <Parameter name="center">0,0,2</Parameter>
  <Parameter name="format">png8</Parameter>
  <Parameter name="minzoom">0</Parameter>
  <Parameter name="maxzoom">14</Parameter>
  <Parameter name="scale">1</Parameter>
  <Parameter name="metatile">2</Parameter>
  <Parameter name="id"><![CDATA[adm]]></Parameter>
  <Parameter name="_updated">1401738882000</Parameter>
  <Parameter name="tilejson"><![CDATA[2.0.0]]></Parameter>
  <Parameter name="scheme"><![CDATA[xyz]]></Parameter>
</Parameters>


<Style name="adm" filter-mode="first">
  <Rule>
    <LineSymbolizer stroke="#559944" stroke-width="0.5" />
    <PolygonSymbolizer fill-opacity="1" fill="#aaee88" />
  </Rule>
</Style>
<Layer name="adm"
  srs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs">
    <StyleName>adm</StyleName>
    <Datasource>
       <Parameter name="file"><![CDATA[{}]]></Parameter>
       <Parameter name="id"><![CDATA[adm]]></Parameter>
       <Parameter name="project"><![CDATA[adm]]></Parameter>
       <Parameter name="srs"><![CDATA[]]></Parameter>
       <Parameter name="type"><![CDATA[shape]]></Parameter>
    </Datasource>
  </Layer>

</Map>
EOF
)

echo "$xml" > '$2'/$( basename {} shp)xml
'
