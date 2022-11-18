#!/bin/bash

function prepsurfyaml {
cat <<EOF
variable: $1
clim:
  min: $2
  max: $3
time: $4
level: $5
latitude: 0.0
color: seismic # Spectral  #seismic #jet 
aggregate: False
projection: 'hat10'
experiment: 'RTOFS'
EOF
}

rtofs3d=/work/noaa/da/kritib/soca-shared/DATA/validation_datasets/RTOFS_regridding_for_Jong/2020/3d

START_YMD=20200825
  END_YMD=20200825

startdate=$(date -I -d "$START_YMD") || exit -1
enddate=$(date -I -d "$END_YMD")     || exit -1

d="$startdate"
YMD=${START_YMD}

while [ "$YMD" -le "$END_YMD" ]; do
echo $YMD

cat Laura2020_latlon.txt |grep ${YMD}12 > latlon.txt

for LEVEL in 0 ; do 

echo $YMD LEVEL=$LEVEL

ln -s ${rtofs3d}/mom6_hat10basin.${YMD}12_3d.nc .
rtofsinput=mom6_hat10basin.${YMD}12_3d.nc

varlist=(temperature)
FNAMElist=(${rtofsinput})

tlist=($(seq 0 0))

for tindex in ${tlist[@]} ;do
    for varname in ${varlist[@]}; do
        for FNAME in ${FNAMElist[@]}; do
            case $varname in
                ssh)
                prepsurfyaml $varname -0.6 0.6 $tindex surface > plot.yaml
                ;;
                temperature)
                prepsurfyaml $varname 18 35 $tindex $LEVEL > plot.yaml
                ;;
                Temp)
                prepsurfyaml $varname 18 35 $tindex $LEVEL > plot.yaml
                ;;
                *)
                echo "clim not defined. Using default"
                prepsurfyaml $varname -1.5 1.5 $tindex surface > plot.yaml                      ;;
            esac
            ./rtofs_plothat10 -g soca_gridspec.nc -f $FNAME -s horizontal \
                             -y plot.yaml
exit

        done
    done
done

d=$(date -I -d "$d + 1 day")
YMD=$(date -d "$d" +%Y%m%d)

done  # day loop

done  # level loop

mkdir NC
mv mom6*.nc NC/.

mkdir PNG
mv *.png PNG/.

exit

