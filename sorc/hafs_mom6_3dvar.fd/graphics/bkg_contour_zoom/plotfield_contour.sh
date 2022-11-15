#!/bin/bash

python_dir=/work/noaa/ng-godas/yli/plot112
grid_dir=/work/noaa/ng-godas/yli/plot112

START_YMDH=20220925Z12
END_YMDH=2022092618
DH=6
ab=bkg

cycle_dir=/work/noaa/stmp/yli/Ian2022_3dvar/2022092512

function prepsurfyaml {
cat <<EOF
variable: $1
clim:
  min: $2
  max: $3
time: $4
level: $5
latitude: 0.0
color: seismic # Spectral #jet 
aggregate: False
projection: 'hat10'
experiment: '2512.zm.Ian2022.3dvar.bkg'
EOF
}

for LEVEL in 0; do 
date_YMDH=$(date -ud "$START_YMDH")
YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
echo $date_YMDH

while [ "$YMDH" -le "$END_YMDH" ]; do

echo $YMDH
cat Ian2022_latlon.txt |grep ${YMDH} > latlon.txt

inputnc=ocn.${ab}.${YMDH}.nc

ln -sf ${cycle_dir}/${ab}/${YMDH:0:4}/${YMDH}/ctrl/${inputnc} .

varlist=(Temp)  #  Salt ave_ssh)
#varlist=(ave_ssh)
FNAMElist=(${inputnc})

tlist=($(seq 0 0))
#tlist=(20) # list of time indices to plot

for tindex in ${tlist[@]} ;do
    for varname in ${varlist[@]}; do
        for FNAME in ${FNAMElist[@]}; do
            case $varname in
                ave_ssh)
                prepsurfyaml $varname -0.6 0.6 $tindex surface > plot.yaml
                ;;
                Salt)
                prepsurfyaml $varname 30 38 $tindex $LEVEL > plot.yaml
                ;;
                Temp)
                prepsurfyaml $varname 18 35 $tindex $LEVEL > plot.yaml
                ;;
                *)
                echo "clim not defined. Using default"
                prepsurfyaml $varname -1.5 1.5 $tindex surface > plot.yaml                      ;;
            esac

            ./plotfield_contour -g ${grid_dir}/soca_gridspec.nc -f $FNAME \
                             -s horizontal -y plot.yaml
#exit
        done
    done
done

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
DH=$(($DH+6))

done  # day loop

done  # level loop

mkdir NC
mkdir PNG

mv *png PNG/.
mv *nc NC/.

exit

