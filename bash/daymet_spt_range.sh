#!/bin/bash

set -o errexit -o pipefail -o noclobber -o nounset

#Daymet available

# -v
vars="year, yday, dayl, prcp, srad, swe, tmax, tmin, vp"
# -s
start="1980-01-01"
# -e
end="2020=132-31"
# -f
format="csv"

inF="./latlon.csv"

# overide the default variable values in the head of the input file

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.


# overwite with our own variables if they are proviced

while getopts "v:s:e:f:i:" opt; do
    case "$opt" in
    v)  vars="$OPTARG"
        ;;
    s)  start="$OPTARG"
        ;;
    e)  end="$OPTARG"
        ;;
    f)  format="$OPTARG"
        ;;
    i)  inF="$OPTARG"
        ;;
    esac
done


# read in first command line argument (should be csv file with lat lon per row)

# check if first command line argument exists and is not empty
if [ -z "$inF" ] ; then
  echo "Error: No lat,lon csv input file provided  with '-i'"
  echo "Usage: ./$0  -v [vars] -s [start-date] -e [end-date] -f [format] -i <input.csv>"
  exit 1
fi

inFs=()
lats=()
lons=()


while IFS=, read -r lat lon ; do
  inFs+=("lat_${lat}_lon_${lon}.out")
  lats+=("$lat")
  lons+=("$lon")
done < "$inF"

if [ -x "$(command -v curl)" ]; then
  downloadwName() {curl --silent "$1" > "$2";}

elif [ -x "$(command -v wget)" ]; then
  downloadwName() {wget --quiet "$1" --output "$2"}
else
  echo "Error: You must have either curl or wget installed to run this script."
  exit 1
fi

for key in "${!lats[@]}"; do

  # https://daymet.ornl.gov/single-pixel/api/data?lat=44&lon=-123&vars=lat,lon,year,yday,dayl,tmax,tmin&start=1980-01-01&end=1980-12-31&format=csv
  query="https://daymet.ornl.gov/single-pixel/api/data?lat=${lats[$key]}&lon=${lons[$key]}&vars=$vars&start=$start&end=$end&format=$format"
  echo "Fetching: $query"
  downloadwName "$query"  "${inFs[$key]}"

done
echo ""
