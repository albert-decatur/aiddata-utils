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
#	aid must fall within an allgeom to be considered when prec code is not 1, and to be clipped properly to a prec coce 2 (clipped by the adm0 it falls into)
#	the following fields must in the inaid table:
#		project_id,precision_code,latitude,longitude, financial field of user's choice
#	assumes srid of allgeom and template raster is EPSG:4326
#	assumes 36000, 17363 columns and rows in the EPSG:4326 template raster (that's '-te -180 -90 180 90 -tr 0.01 0.01' in gdal_rasterize speak)
# would be useful for comparing a series of scenarios and describing how the current distribution might be the result of several of these
# TODO - make nodata a variable
# example use: $0 m4r usd allgeom climate_cities adecatur template_rast /tmp/

inaid=$1
infinancials=$2
ingeom=$3
db=$4
user=$5
template_rast=$6
outdir=$7

function add_template_rast {
	echo "drop table if exists $( basename $template_rast .tif);" | psql $db
	# using -R b/c raster often too big for physical import to db
	raster2pgsql -R $template_rast | psql $db
	# from now on var for template_rast will be the basename - ie, the table name in psql
	template_rast=$( basename $template_rast .tif)
}

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
		# allow for double quote separated multiple prec codes like "5 6 8"
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
				a.gid,
				sum(i.financials_per_loc) as financials,
				a.geom
			from 
				intermediate_locs as i,
				allgeom as a 
			where 
				( $prec_code_where ) 
				and a.adm_level = '$adm' 
				and st_within(i.geom,a.geom) 
			group by 
				a.gid
			;"
	}
# mk prec code 1 table - move all lat/lng over to template pixels after summing financials to template pixels
# this prevents us from having to use st_union(rast,'SUM') which fails
echo "
	drop table prec1;
	create table prec1 as 
	select
		tmp.financials_per_loc as financials,
		st_setsrid((st_makepoint(ST_RasterToWorldCoordX((select rast from $template_rast),tmp.xcol),ST_RasterToWorldCoordY((select rast from $template_rast),tmp.ycol))),4326) as geom 
	from 
		( 
			select 
				sum(p.financials_per_loc) as financials_per_loc,
				st_worldtorastercoordx((select rast from $template_rast),p.geom) as xcol,
				st_worldtorastercoordy((select rast from $template_rast),p.geom) as ycol 
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
				-- ensure that all points snap to the template pixels and group their financials by these pixels
				-- this cuts down on the number of layers for map algebra later
				st_worldtorastercoordx((select rast from $template_rast),p.geom),st_worldtorastercoordy((select rast from $template_rast),p.geom)
		) as tmp
	;
	alter table prec1 add column gid SERIAL
	;"
# mk prec code 2 table - buffer point by 25km and clip to adm0 it falls under
echo "
	drop table _prec2;
	create table _prec2 as 
	select
		tmp.financials_per_loc as financials,
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
				intermediate_locs as i
				,allgeom as a 
			where 
				st_within(i.geom,a.geom) 
				and a.adm_level = '0' and
				i.precision_code = '2'
		) as tmp
	;
	alter table _prec2 add column gid SERIAL
	;
	-- ensure there are no geometry collections by converting to multipolygon
	-- this is necessary to make table prec2_nointersect
	drop table prec2;
	create table prec2 as 
	select 
		gid,
		financials,
		case when 
			st_geometrytype(geom) = 'ST_GeometryCollection' 
		then 
			ST_CollectionExtract(geom,3) 
		else 
			geom 
		end as geom 
	from 
		_prec2
	;
	-- make a single table for prec2 polys where there is no intersection
	-- this cuts down on the number of layers in map algebra later
	drop table prec2_nointersect;
	create table prec2_nointersect as
	select 
		* 
	from 
		prec2 as p 
	where 
		p.gid not in ( 
			select 
				a.gid 
			from 
				prec2 as a,
				prec2 as b 
			where 
				st_intersects(a.geom,b.geom) 
				and a.gid != b.gid 
			group by 
				a.gid,a.financials,a.geom 
		)
	;
	-- take the inverse of prec2_nointersect, meaning prec2 polys that do overlap at least one other prec2 poly
	-- note that either of these tables prec2_nointersect or prec2_intersect can legitimately have 0 records, which could cause problems for the script
	drop table prec2_intersect; 
	create table prec2_intersect as 
	select 
		* 
	from 
		prec2 as a 
	where 
		a.gid not in ( 
				select 
					b.gid 
				from 
					prec2_nointersect as b
			)
	;"
# get geoms for prec 3
by_adm 3 2
# get geoms for prec 4
by_adm 4 1
# get geoms for prec 6 or 8
by_adm "5 6 8" 0
}

# make GIST index for each precision code table
function mk_index { 
	for table in prec{1..4} prec568
	do
		echo "create index i_${table} on $table using gist(geom);"
	done
}

# rasterize the precision geom layers, with one layer each for prec{1,3,4,568} and one raster per feature for pre2 (they overlap) 
function rasterize {
	# export tifs for prec{1,2_nointeresects,3,4,568}, and for each prec2_intersects raster
	# next we can use numpy to get a sum
	# have to count pixels first for prec other than 1

	# rm previous output rasters - hope these were not needed!
	rm /tmp/prec*.tif 2>/dev/null
	# export prec1 as shp then gdal_rasterize to same dimensions as template
	# this is not ideal because now the template raster and gdal_rasterize have to use the same rows/cols and pixel width/height and SRS
	# this is because there is an issue with nulls when using st_asraster on prec1 which does not seem to be the result of nodata or pixeltype
	gdal_rasterize -co COMPRESS=DEFLATE -a_srs EPSG:4326 -a financials -l prec1 -te -180 -90 180 90 -tr 0.01 0.01 PG:"dbname='$db' host='localhost' port='5432' user='$user'" /tmp/prec1.tif
	# export prec{2_nointeresects,3,4,568} as raster but first have to establish the count of pixels and update their financials as ( sum_financials / count_pixels )
	# make dir for all prec rasters to go into, including 2_intersects dir
	allprecdir=$(mktemp -d)
	for n in 2_nointersect 2_intersect 3 4 568
	do
		# make tmp dir for output rasters
		tmpdir=$(mktemp -d)
		# for each gid, get a tif where values are ( sum_financials for poly / pixel count for poly )
		# later gdalbuildvrt to make mosaic
		# this is just to avoid the slow st_union
		a="'"
		echo "copy ( select gid from prec${n} ) to stdout" |\
		psql $db |\
		parallel --gnu '
			echo "
				copy ( 
					select 
						encode(
							(
								st_asgdalraster(
									weighted.rast,'$a'GTiff'$a',ARRAY['$a'COMPRESS=DEFLATE'$a'],4326
								)
							),'$a'hex'$a'
						) 
					from 
						( 
							select 
								st_asraster(tmp.geom,(select rast from '$template_rast'),'$a'32BF'$a',(financials/st_count(tmp.rast)),0) as rast 
							from 
								( 
									select 
										geom,
										financials,
										st_asraster(geom,(select rast from '$template_rast'),'$a'32BF'$a',financials,0) as rast 
									from 
										prec'$n' 
									where 
										gid = {} 
								) as tmp 
						) as weighted 
				) to stdout;" |\
			psql '$db' |\
			# encode back to binary
			xxd -p -r > '$tmpdir'/prec${n}_{}.tif
		'
		if [[ $n == "2_intersect" ]]; then
			if [[ $( find $tmpdir -type f | wc -l ) -gt 0 ]]; then
				mv $tmpdir $allprecdir/
			fi
		else
			cd /tmp/
			gdalbuildvrt ${allprecdir}/prec${n}.vrt $tmpdir/*.tif
			gdal_translate -co COMPRESS=DEFLATE ${allprecdir}/prec${n}.vrt ${allprecdir}/prec${n}.tif
			rm -r $tmpdir
			rm ${allprecdir}/prec${n}.vrt
		fi
	done
	# mv prec1 tif into same dir as everything else
	mv /tmp/prec1.tif ${allprecdir}
	# for all prec, build gdal virtual that can be imported into numpy
	cd /tmp/
	gdalbuildvrt prec.vrt -a_srs EPSG:4326 -srcnodata 0 -separate $( find $allprecdir -type f )
	# rename to be outdir                                                                                                                                          
	mv ${allprecdir} $outdir 
}

add_template_rast
mk_intermediate_locs | psql $db
mk_prec_tables | psql $db
mk_index | psql $db
rasterize
