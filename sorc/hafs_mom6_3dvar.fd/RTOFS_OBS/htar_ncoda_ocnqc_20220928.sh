#!/bin/bash

module load hpss

#YMD=20221012
YMD=20220915
rtofspath=/NCEPPROD/5year/hpssprod/runhistory/rh2022
htar -xv -f ${rtofspath}/${YMD:0:6}/${YMD}/com_rtofs_v2.3_rtofs.${YMD}.ncoda.tar 
exit

#/NCEPPROD/5year/hpssprod/runhistory/rh2022/202209/20220928/com_rtofs_v2.3_rtofs.20220928.ncoda.tar

#           /NCEPDEV/emc-ocean/5year/emc.ncodapa/nco_parallel
htar -xv -f /NCEPPROD/5year/hpssprod/runhistory/rh2022/${YMD:0:6}/${YMD}/com_rtofs_v2.3_rtofs.${YMD}.ncoda.tar ./ncoda/ocnqc/profile/*.profile
exit

exit


scp sst_amsr_2022* yongzuo@Orion-login-1.HPC.MsState.Edu:/work/noaa/marine/yli/RTOFS_OBS/NC
scp sst_npp_2022* yongzuo@Orion-login-1.HPC.MsState.Edu:/work/noaa/marine/yli/RTOFS_OBS/NC

START_YMDH=20200815Z00
END_YMDH=2020082000
DH=24
mkdir data

date_YMDH=$(date -ud "$START_YMDH")
echo $date_YMDH

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )

while [ "$YMDH" -le "$END_YMDH" ]; do

echo ${YMDpath} ${YMDH}

#htar -xv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/parallel/ncoda.${YMDpath}/ocnqc.tar ocnqc/profile/${YMDH}.profile
htar -xv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/nco_parallel/ncoda.${YMDpath}/ocnqc.tar ocnqc/profile/${YMDH}.profile

cd data
ln -s ../ocnqc/profile/${YMDH}.profile .
cd -

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
DH=$(($DH+24))
exit
done

exit

htar -tv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/nco_parallel/ncoda.20201028/ocnqc.tar > ncoda.20210812.table
htar -tv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/emc_parallel3/ncoda.20210812/ocnqc.tar > ncoda.20210812.table
htar -tv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/parallel/ncoda.20201024/ocnqc.tar > ncoda.20201024.table

htar -tv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/parallel/ncoda.20200821/ocnqc.tar > ncoda.20200821.table

cd SCP

scp -r 202010* yongzuo@Orion-login-1.HPC.MsState.Edu:/work/noaa/ng-godas/yli/plot112/rtofs_profile/data


scp -r 20210* yongzuo@Orion-login-1.HPC.MsState.Edu:/work/noaa/marine/yli/soca-shared/DATA/obs/RTOFSobs4MOM6_24h/rtofs_profile/data

htar -tv -f /NCEPDEV/emc-ocean/5year/emc.ncodapa/parallel/rtofs.20200808/rtofs.ncoda.tar > rtofs.20200808.table
scp -r 20200* yongzuo@Orion-login-3.HPC.MsState.Edu:/work/noaa/ng-godas/yli/plot112/rtofs_profile/data

module load hpss
