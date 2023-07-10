#!/bin/sh

##set -x

############################### User input ################################
export YMDH1=2022091212
#export YMDH2=2022092812
export YMDH2=Ian2022_0920_0928

mkdir Ian2022
cd Ian2022
rm obc_*.nc

ncrcatpath=/apps/intel-2020.2/nco-4.9.3/bin

# Concatenate in time OBC files 
for segm in north east south; do

    echo Concatenating ${segm} 'segment'
    ${ncrcatpath}/ncrcat ../${YMDH1}/obc_ssh_${segm}.nc ../${YMDH2}/obc_ssh_${segm}.nc obc_ssh_${segm}.nc
    ${ncrcatpath}/ncrcat ../${YMDH1}/obc_ts_${segm}.nc ../${YMDH2}/obc_ts_${segm}.nc obc_ts_${segm}.nc
    ${ncrcatpath}/ncrcat ../${YMDH1}/obc_uv_${segm}.nc ../${YMDH2}/obc_uv_${segm}.nc obc_uv_${segm}.nc

done

exit

