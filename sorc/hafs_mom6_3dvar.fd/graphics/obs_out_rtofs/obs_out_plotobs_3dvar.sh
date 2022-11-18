#!/bin/bash

python_dir=/work/noaa/marine/yli/soca-shared/soca-diagnostics

obs_out_dir=/work/noaa/stmp/yli/Ian2022_3dvar/2022092312

START_YMDH=2022092318
  END_YMDH=2022092400
DH=6

tmp_YMDH=$(date -ud "${START_YMDH:0:8}Z${START_YMDH:8:2}")
YMDH=$(date -ud "$tmp_YMDH " +%Y%m%d%H )

mkdir NC
mkdir PNG

while [ "$YMDH" -le "$END_YMDH" ]; do

echo $YMDH

  echo ${obs_out_dir}/obs_out/${YMDH:0:4}/${YMDH}/ctrl

rm *nc
ln -sf ${obs_out_dir}/obs_out/${YMDH:0:4}/${YMDH}/ctrl/*nc .

#varlist=(Temp Salt ave_ssh insitu)
#varlist=(profile)
varlist=(Temp)

for varname in ${varlist[@]}; do

	case $varname in
                ave_ssh)
for inputnc in `ls adt*nc` ; do
time=${YMDH}
pre=${inputnc:0:15}
var=${pre%.*}
outputpng=${time}.${var}.png
./obs_out_plotobs_3dvar_ALL -f ${inputnc} -v absolute_dynamic_topography -g ObsValue \
               -b -1.0 1.0 -d hat10 -t ${var}_${time} -s ${outputpng}
done
;;

                Salt)
for inputnc in `ls sss*nc` ; do
time=${YMDH}
pre=${inputnc:0:15}
var=${pre%.*}
outputpng=${time}.${var}.png
./obs_out_plotobs_3dvar -f ${inputnc} -v sea_surface_salinity -g ObsValue \
               -b 30 38 -d hat10 -t ${var}_${time} -s ${outputpng}
done
;;

                Temp)
for inputnc in `ls sst*.${YMDH}.nc` ; do
time=${YMDH}
pre=${inputnc:0:15}
var=${pre%.*}
outputpng=${time}.${var}.png
./obs_out_plotobs_3dvar -f ${inputnc} -v sea_surface_temperature -g ObsValue \
               -b 5 30 -d hat10 -t ${var}_${time} -s ${outputpng}
done
;;

                profile)
for inputnc in `ls temp_profile.*.nc` ; do
time=${YMDH}
pre=${inputnc:0:15}
var=${pre%.*}
outputpng=${time}.sws.${var}.png
./obs_out_plotobs_3dvar -f ${inputnc} -v sea_water_salinity -g ObsValue \
               -b 30 40 -d hat10 -t sws_profile_$time -s ${outputpng}
outputpng=${time}.swt.${var}.png
./obs_out_plotobs_3dvar -f ${inputnc} -v sea_water_temperature -g ObsValue \
               -b 5 35 -d hat10 -t swt_profile_$time -s ${outputpng}
done
;;
esac

done  # var loop
#exit

mv *nc NC/.
mv *png PNG/.

YMDH=$(date -ud "$tmp_YMDH + $DH hours" +%Y%m%d%H )
DH=$(($DH+6))

done  # day loop

