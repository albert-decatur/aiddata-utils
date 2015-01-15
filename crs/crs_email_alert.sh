#!/bin/bash

# if there is a new version of CRS send me an email
# put this in cron!
# user args: 1) directory to find latest crs txt, name like so 'crsYYYY-MM-DD.txt', 2) email address to send notice to
# example use: nohup $0 scratch/ data@aiddata.org &

checkdir=$1
email=$2

# get latest date mentioned by CRS download webpage
crs_latest=$(
	w3m -dump "http://stats.oecd.org/DownloadFiles.aspx?HideTopMenu=yes&DatasetCode=CRS1" 2>/dev/null |\
	grep -oE "[0-9]{2}/[0-9]{2}/[0-9]{4}"|\
	sort|\
	uniq|\
	awk -F'/' '{OFS="-"; print $3,$2,$1}'|\
	sort -rn|\
	sed -n '1p'
)

# get latest crs in checkdir
my_latest=$(
	find $checkdir -type f -iregex ".*crs.*[.]txt"|\
	sort -rn|\
	sed -n '1p'|\
	grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}"
)

# if crs latest is newer than my latest, send an email
if [[ $crs_latest > $my_latest ]]; then
	echo "new CRS is available at http://stats.oecd.org/DownloadFiles.aspx?HideTopMenu=yes&DatasetCode=CRS1" | mutt -s "new CRS available" $email
fi
