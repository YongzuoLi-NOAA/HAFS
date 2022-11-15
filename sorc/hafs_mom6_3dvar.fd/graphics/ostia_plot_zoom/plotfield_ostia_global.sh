#!/bin/bash

START_YMD=20220925
  END_YMD=20220925

startdate=$(date -I -d "$START_YMD") || exit -1
enddate=$(date -I -d "$END_YMD")     || exit -1

d="$startdate"
YMD=${START_YMD}

while [ "$YMD" -le "$END_YMD" ]; do
echo $YMD

cat Ian2022_latlon.txt |grep ${YMD}12 > latlon.txt

#rm ostia.nc
#ln -s /work/noaa/ng-godas/marineda/validation/OSTIA/${YMD}/${YMD}120000-UKMO-L4_GHRSST-SSTfnd-OSTIA-GLOB-v02.0-fv02.0.nc ostia.nc

./plotfield_ostia_global -f ./ostia.nc -s horizontal -y plot.yaml -d ${YMD}12

d=$(date -I -d "$d + 1 day")
YMD=$(date -d "$d" +%Y%m%d)

done  # day loop

mkdir PNG
mv *.png PNG/.

