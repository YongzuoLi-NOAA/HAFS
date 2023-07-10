#!/bin/sh

##set -x
# https://www.ncei.noaa.gov/erddap/convert/time.html?n=44471.5&units=days+since+1900-12-31
############################### User input ################################
#export YMDH=${YMDH:-2020082512}
#export YMDH=${YMDH:-2020072012}
#export YMDH=${YMDH:-2020082412}
export YMDH=2022091212
Length_days=7

export HOMEwork=/work/noaa/marine/yli/RTOFS_OBC # Tools and HAT10 settings
#export HOMEhafs=/work/noaa/hwrf/save/maristiz/hafs_develop_202112
export HOMEhafs=/work/noaa/hwrf/noscrub/hafs-fix-files/hafs-20210520-fix
export HOMErtofs=/work/noaa/hwrf/noscrub/hafs-input/COMRTOFSv2
export GRIDmom6=/work/noaa/hwrf/save/maristiz/scripts_to_prep_MOM6/RTOFS_OBC/hat10/ocean_hgrid.nc
#export Exp_name=${Exp_name:-ocean_only_HAT10_${YMDH}}

############################### End user input ################################

# Create experiment folder
mkdir ${YMDH}
cd ${YMDH}

# Load modules
#module purge
export MACHINE=orion.intel
source /work/noaa/hwrf/save/maristiz/HAT10_MOM6_from_HeeSook/expdir_OBC3/soca-science/configs/machine/machine.orion.intel

#<<com
# Link global RTOFS depth and grid files
rm -f regional*
ln -s ${HOMEhafs}/fix/fix_hycom/rtofs_glo.navy_0.08.regional.depth.a regional.depth.a
ln -s ${HOMEhafs}/fix/fix_hycom/rtofs_glo.navy_0.08.regional.depth.b regional.depth.b

ln -s ${HOMEhafs}/fix/fix_hycom/rtofs_glo.navy_0.08.regional.grid.a regional.grid.a
ln -s ${HOMEhafs}/fix/fix_hycom/rtofs_glo.navy_0.08.regional.grid.b regional.grid.b

Hour=${YMDH:8:2}
echo $Hour

if [ "${Hour}" == "00" ]
then
    type=${type:-n}
    echo ${type}
else 
    type=${type:-f}
    echo ${type}
fi


# Link global RTOFS analysis or forecast files
rm -f archv_in.[ab]

for n in $(seq 0 $Length_days); do
        #echo ${n}
        # Print the year:month:day to be processed:
        unset date
        unset Year
        unset Month
        unset Day
        unset Hour
        unset outnc_UV
        unset outnc_TS
        #unset outnc_3d
        unset outnc_2d
        date=( $(python3 ${HOMEwork}/get_cycle.py $YMDH -nday $n) )
        Year=${date[0]}

        month=${date[1]}
        if [ ${#month} -lt 2 ]
        then
           Month=${Month:-0$month}
        else
           Month=${Month:-$month}
        fi

        day=${date[2]}
        if [ ${#day} -lt 2 ]
        then
           Day=${Day:-0$day}
        else
           Day=${Day:-$day}
        fi

        hour=${date[3]}
        if [ ${#hour} -lt 2 ]
        then
           Hour=${Hour:-0$hour}
        else
           Hour=${Hour:-$hour}
        fi

        echo $Year$Month$Day$Hour

        # Link the RTOFS output for the correct cycle 
        ln -sf ${HOMErtofs}/rtofs.$Year$Month$Day/rtofs_glo.t00z.${type}${Hour}.archv.a.tgz
        tar -xpvzf rtofs_glo.t00z.${type}${Hour}.archv.a.tgz
        ln -sf rtofs_glo.t00z.${type}${Hour}.archv.a archv_in.a
        ln -sf ${HOMErtofs}/rtofs.$Year$Month$Day/rtofs_glo.t00z.${type}${Hour}.archv.b archv_in.b

        # Define output file names
        outnc_UV=${outnc_UV:-rtofs_HAT10_${Year}${Month}${Day}_${type}${Hour}_UV.nc}
        outnc_TS=${outnc_TS:-rtofs_HAT10_${Year}${Month}${Day}_${type}${Hour}_TS.nc}
        #outnc_3d=${outnc_UV:-rtofs_HAT10_${Year}${Month}${Day}_${type}${Hour}_TSUV.nc}
        outnc_2d=${outnc_2d:-rtofs_HAT10_${Year}${Month}${Day}_${type}${Hour}_SSH.nc}

        export CDF033=./${outnc_UV}
        export CDF034=./${outnc_TS}
        #export CDF033=./${outnc_3d}
        export CDF038=./${outnc_2d}

        #rm $CDF033 $CDF038

        # run RTOFS executables to produce netcdf files
        ${HOMEwork}/archv2ncdf3z < ${HOMEwork}/ncdf3z_rtofs_3d_hat10_OBC.in

        ${HOMEwork}/archv2ncdf2d < ${HOMEwork}/ncdf3z_rtofs_SSH_hat10_OBC.in

done
#com
# Run Python script to generate OBC 
/work/noaa/hwrf/save/maristiz/miniconda3/bin/python3 ${HOMEwork}/gen_obc_from_RTOFS.py ${GRIDmom6} ./ ./

ncrcatpath=/apps/intel-2020.2/nco-4.9.3/bin
rm obc_*.nc
# Concatenate in time OBC files 
for segm in north east south; do
   
    echo Concatenating ${segm} 'segment'
    ${ncrcatpath}/ncrcat rtofs_HAT10_*obc_${segm}_SSH.nc obc_ssh_${segm}.nc
    ${ncrcatpath}/ncrcat rtofs_HAT10_*obc_${segm}_TS.nc obc_ts_${segm}.nc
    ${ncrcatpath}/ncrcat rtofs_HAT10_*obc_${segm}_UV.nc obc_uv_${segm}.nc

done

# Make ridiculous values = 0
#ncap2 -s 'where (ssh_segment_001 > 50.0 ) ssh_segment_001=0.0' obc_ssh_north.nc
#ncap2 -s 'where (ssh_segment_001 < -50.0 ) ssh_segment_001=0.0' obc_ssh_north.nc
#ncap2 -s 'where (ssh_segment_002 > 50.0 ) ssh_segment_002=0.0' obc_ssh_south.nc
#ncap2 -s 'where (ssh_segment_002 < -50.0 ) ssh_segment_002=0.0' obc_ssh_south.nc
#ncap2 -s 'where (ssh_segment_003 > 50.0 ) ssh_segment_003=0.0' obc_ssh_east.nc
#ncap2 -s 'where (ssh_segment_003 < -50.0 ) ssh_segment_003=0.0' obc_ssh_east.nc

