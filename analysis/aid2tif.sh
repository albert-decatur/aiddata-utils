#!/bin/bash

# assign geoms to aiddata points and then rasterize and sum - assume distribution by first even split between locations and then even split along surface area
# this holds true even for prec1 pixels - summed financials are divided by pixel-by-pixel surface area (good for any units, eg WGS84's degrees)
# assign adm0,adm1,adm2,25 km buffered point, or just initial aid point based on precision code, lat, lng
# assign financials based on input field of users choice - assumed to be at project level, distributed evenly across project locations
# inputs: postgres table with { projectid, financials column, precision code, lat, lng }, **and** allgeom table in postgis from GAUL boundaries with adm_level field (0|1|2) and geom field
# output: raster with user's choice of x/y res with financials by pixel
# NB: 
#	if tables exist they must be d#ropped manually
#	input aid table must have valid lng,lat, be wgs84, prec code must be {1,2,3,4,5,6,8}
#	financials must refer to project level
#	aid must fall within an allgeom to be considered when prec code is {3,4}, and to be clipped properly to a prec coce 2 (clipped by the adm0 it falls into)
#	the following fields must in the inaid table:
#		project_id,precision_code,latitude,longitude, financial field of user's choice
#	assumes srid of allgeom is EPSG:4326
# TODO: modify to allow for dasymetric output rasters, eg weight in-polygon split by an input raster like population, poverty, flood risk, ag output, etc
# would be useful for comparing a series of scenarios and describing how the current distribution might be the result of several of these
# example use: $0 m4r usd allgeom climate_cities /tmp/out.tif

inaid=m4r
infinancials=usd
ingeom=allgeom
db=scratch
outrast=/tmp/out.tif
rm $outrast 2>/dev/null

function mk_intermediate_locs {
	# make an intermediate table with financials_per_loc, assuming an even split of project funds between all project locs
	echo "
		drop table intermediate_locs;
		create table intermediate_locs as 
			select 
				$inaid.project_id,
				a.financials_per_loc,
				$inaid.precision_code,
				st_setsrid(st_makepoint($inaid.longitude::numeric,$inaid.latitude::numeric),4326) as geom 
			from 
				$inaid 
				inner join 
					( 
						select 
							project_id,
							count(*) as count_locs,
							round($infinancials::numeric/(count(*)),2) as financials_per_loc
						from 
							$inaid 
						where 
							longitude is not null 
							and latitude is not null 
						group by 
							project_id,$infinancials 
					) as a 
				on 
				$inaid.project_id = a.project_id
				;"
}

# make geometry for each precision code 1,2,3,4,5,6,8
# assign GAUL2013 geom ADM0,1,2 where appropriate - aggregate to these geoms
# divide financials by area
function mk_prec_tables {
# make function for geom by adm 0,1,or 2 - first arg is prec code second arg is adm_level from allgeom
# note that this allows for multiple precision codes, good for prec code 6 and 8 which both refer to adm0
	function by_adm {
	if [[ $( echo "$1" | wc -w ) -eq 1 ]]; then
		prec_code_table=$1
		prec_code_where="i.precision_code = '${1}'"
	else
		# allow for double quote separated multiple prec codes like "6 8"
		prec_code_table=$(
			echo "$1" |\
			sed 's: ::g'
		)
		prec_code_where=$(
			echo "$1" |\
			tr ' ' '\n' |\
			sed "s:^:i.precision_code = ':g;s:$:' or:g"|\
			tr '\n' ' ' |\
			sed 's: or\s*$::g'
		)
	fi
	adm=$2
		echo "
			drop table prec${prec_code_table};
			create table prec${prec_code_table} as 
			select 
				( financials_per_loc / ( st_area(geom::geography)/1000000 ) ) as financials,
				geom
			from 
				(
					select 
						financials_per_loc,
						a.geom 
					from 
						( 
							select 
								sum(i.financials_per_loc) as financials_per_loc,
								a.gid as geom_id 
							from 
								intermediate_locs as i,
								allgeom as a 
							where 
								( $prec_code_where ) 
								and a.adm_level = '$adm' 
								and st_within(i.geom,a.geom) 
							group by 
								a.gid 
						) as tmp,
						allgeom as a 
					where 
						a.gid = tmp.geom_id 
				) as a
			;
			alter table prec${prec_code_table} add column gid SERIAL
			;"
	}
# mk prec code 1 table - move all lat/lng over to template pixels after summing financials to template pixels
# this prevents us from having to use st_union(rast,'SUM') which fails
# use Lambert Azimuthal Equal-Area, find pixel surface area and divide financials by it to get aid per sqkm, export points to shapefile, rasterize with gdal, and then incorporate to map algebra
# it is perhaps more correct to pursue calculating the area of individual pixels with degrees as map units (which I did implement), but this creates the problem of PostGIS coming up with null pixels when it should not
echo "
	drop table prec1;
	create table prec1 as 
	select
		tmp.financials_per_loc as financials,
		st_setsrid((st_makepoint(ST_RasterToWorldCoordX((select rast from template),tmp.xcol),ST_RasterToWorldCoordY((select rast from template),tmp.ycol))),4326) as geom 
	from 
		( 
			select 
				sum(p.financials_per_loc) as financials_per_loc,
				st_worldtorastercoordx((select rast from template),p.geom) as xcol,
				st_worldtorastercoordy((select rast from template),p.geom) as ycol 
			from
				(
					select 
						i.project_id,
						i.financials_per_loc,
						i.geom 
					from 
						intermediate_locs as i 
					where 
						i.precision_code = '1'
				) as p
			group by 
				st_worldtorastercoordx((select rast from template),p.geom),st_worldtorastercoordy((select rast from template),p.geom)
		) as tmp
	;
	alter table prec1 add column gid SERIAL
	;"
# mk prec code 2 table - buffer point by 25km and clip to adm0 it falls under
echo "
	drop table prec2;
	create table prec2 as 
	select
		( tmp.financials_per_loc / ( st_area(tmp.geom::geography)/1000000 ) ) as financials,
		tmp.geom
	from 
		(
			select
				i.project_id,
				i.financials_per_loc,
				-- clip the 25km buffer to the adm0 that the point lies in
				st_intersection(
					(
						-- make the 25km bufer
						(st_buffer(i.geom::geography,25000)::geometry)
					),
					st_makevalid(a.geom)
				) as geom 
			from
				intermediate_locs as i,
				allgeom as a 
			where 
				st_within(i.geom,a.geom) 
				and a.adm_level = '0' 
				and i.precision_code = '2'
		) as tmp
	;
	alter table prec2 add column gid SERIAL
	;"
# get geoms for prec 3
#by_adm 3 2
# get geoms for prec 4
#by_adm 4 1
# get geoms for prec 6 or 8
#by_adm "5 6 8" 0
}

# make GIST index for each precision code table
function mk_index { 
	for table in prec{1..4} prec568
	do
		echo "create index i_${table} on $table using gist(geom);"
	done
}

# rasterize the precision geom layers, with one layer each for prec{1,3,4,568} and one raster per feature for pre2 (they overlap) 
#function rasterize {
#	
#}

mk_intermediate_locs | psql $db
mk_prec_tables | psql $db
mk_index | psql $db
