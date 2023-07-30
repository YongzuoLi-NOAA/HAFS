#!/bin/bash

export HOMEwork=/scratch2/NCEPDEV/marine/Yongzuo.Li/RTOFS2IODA_V3

#START_YMDH=2022092212
#  END_YMDH=2022092212

START_YMDH=2022090100
  END_YMDH=2022100500

#START_YMDH=2021080900
#  END_YMDH=2021091200

TMP_YMDH=${START_YMDH:0:8}Z${START_YMDH:8:2}
date_YMDH=$(date -ud "$TMP_YMDH")
echo $date_YMDH
DH=6

#SKIP=1
#if [[ SKIP == "0" ]]; then
######################### convert RTOFS SST into IODA v3 ############
platlist=(amsr goes himawari metop npp jpss)

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )

YMDHm3h=$(date -ud "$date_YMDH - 3 hours" +%Y%m%d%H )
YMDHm6h=$(date -ud "$date_YMDH - 6 hours" +%Y%m%d%H )

winstart=$(date -ud "$date_YMDH - 3 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 3 hours" +%Y%m%d%H )
echo $YMDH $END_YMDH
while [ "$YMDH" -le "$END_YMDH" ]; do

echo $winstart $YMDH $winend

for plat in ${platlist[@]}; do

platx=${plat}
if [[ ${plat} == "jpss" ]] || [[ ${plat} == "npp" ]]; then
platx="viirs"
fi
echo ${platx}

rm window.txt
echo ${winstart}00 > window.txt
echo ${winend}00 >> window.txt

rm sst.bin sst.txt sst.thin

if [[ ${plat} == "jpss" ]] || [[ ${plat} == "npp" ]] || [[ ${plat} == "metop" ]]; then
 ls -l ${HOMEwork}/ocnqc/${platx}/${YMDHm3h}.${plat}
ln -sf ${HOMEwork}/ocnqc/${platx}/${YMDHm3h}.${plat} sst.bin
fi

if [[ ${plat} == "goes" ]] || [[ ${plat} == "amsr" ]]; then
 ls -l ${HOMEwork}/ocnqc/${platx}/${YMDHm6h}.${plat}
ln -sf ${HOMEwork}/ocnqc/${platx}/${YMDHm6h}.${plat} sst.bin
fi

${HOMEwork}/rtofs_obs_read.x read_sst
if [[ -f sst.txt ]]; then
mv sst.txt sstab.txt
fi

rm sst.bin
 ls -l ${HOMEwork}/ocnqc/${platx}/${YMDH}.${plat}
ln -sf ${HOMEwork}/ocnqc/${platx}/${YMDH}.${plat} sst.bin
${HOMEwork}/rtofs_obs_read.x read_sst
if [[ -f sst.txt ]]; then
cat sst.txt >> sstab.txt
fi

mv sstab.txt sst.txt

${HOMEwork}/rtofs_obs_thin.x thin_sst

echo "start NETCDF rtofs_ascii2iodav3.py"

${HOMEwork}/rtofs_ascii2iodav3.py -i sst.thin -v seaSurfaceTemperature -o ./sst_${plat}_${YMDH}.nc

done # plat loop

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )

DHm3h=$(($DH-3))
YMDHm3h=$(date -ud "$date_YMDH + $DHm3h hours" +%Y%m%d%H )
DHm6h=$(($DH-6))
YMDHm6h=$(date -ud "$date_YMDH + $DHm6h hours" +%Y%m%d%H )

DHm3h=$(($DH-3))
winstart=$(date -ud "$date_YMDH + $DHm3h hours" +%Y%m%d%H )

DHp3h=$(($DH+3))
winend=$(date -ud "$date_YMDH + $DHp3h hours" +%Y%m%d%H )

DH=$(($DH+6))

done # time loop

if [[ ! -d NC ]]; then
mkdir NC
fi
mv sst_*.nc NC/.

##fi  # SKIP
exit


##SKIP=0
##if [[ SKIP == "0" ]]; then
################### convert RTOFS profile into IODA v3 ##############

DH=6
platlist=(profile)

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
today=${YMDH:0:8}00

YMDHm1d=$(date -ud "$date_YMDH - 19 hours" +%Y%m%d%H )
yesterday=${YMDHm1d:0:8}00

winstart=$(date -ud "$date_YMDH - 3 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 3 hours" +%Y%m%d%H )

while [ "$YMDH" -le "$END_YMDH" ]; do

today=${YMDH:0:8}00
yesterday=${YMDHm1d:0:8}00
echo $winstart $YMDH $winend

for plat in ${platlist[@]}; do

rm window.txt
echo ${winstart}00 > window.txt
echo ${winend}00 >> window.txt

rm profile.bin profile.txt
if [[ ${YMDH:8:2} == "00" ]]; then
ls -l ${HOMEwork}/ocnqc/profile/${yesterday}.${plat}
ln -sf ${HOMEwork}/ocnqc/profile/${yesterday}.${plat} profile.bin
${HOMEwork}/rtofs_obs_read.x read_profile
if [[ -f profile.txt ]]; then
mv profile.txt profileab.txt
fi
fi

ls -l ${HOMEwork}/ocnqc/profile/${today}.${plat}
ln -sf ${HOMEwork}/ocnqc/profile/${today}.${plat} profile.bin
${HOMEwork}/rtofs_obs_read.x read_profile

if [[ -f profile.txt ]]; then
cat profile.txt >> profileab.txt
fi

mv profileab.txt profile.txt
echo start NETCDF

${HOMEwork}/rtofs_ascii2iodav3.py -i temp.txt -v waterTemperature -o ./temp_pfl_${YMDH}.nc
${HOMEwork}/rtofs_ascii2iodav3.py -i salt.txt -v salinity -o ./salt_pfl_${YMDH}.nc

done # plat loop

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )

DHH=$(($DH-12))
YMDHm1d=$(date -ud "$date_YMDH + $DHH hours" +%Y%m%d%H )

DHm3h=$(($DH-3))
winstart=$(date -ud "$date_YMDH + $DHm3h hours" +%Y%m%d%H )

DHp3h=$(($DH+3))
winend=$(date -ud "$date_YMDH + $DHp3h hours" +%Y%m%d%H )

DH=$(($DH+6))

done # time loop

mv temp_pfl_*.nc NC/.
mv salt_pfl_*.nc NC/.

##fi  # SKIP

######################### convert RTOFS SSH into IODA v3 ############

DH=6
platlist=(ssh)
ocnqcpath=${HOMEwork}/ocnqc/ssh

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
today=${YMDH:0:8}00

YMDHm1d=$(date -ud "$date_YMDH - 19 hours" +%Y%m%d%H )
yesterday=${YMDHm1d:0:8}00

winstart=$(date -ud "$date_YMDH - 3 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 3 hours" +%Y%m%d%H )

while [ "$YMDH" -le "$END_YMDH" ]; do

today=${YMDH:0:8}00
yesterday=${YMDHm1d:0:8}00
echo $winstart $YMDH $winend

for plat in ${platlist[@]}; do

rm window.txt
echo ${winstart}0000 > window.txt
echo ${winend}0000 >> window.txt

rm ssh.bin ssh.txt
if [[ ${YMDH:8:2} == "00" ]]; then
ls -l ${ocnqcpath}/${yesterday}.${plat}
ln -sf ${ocnqcpath}/${yesterday}.${plat} ssh.bin
${HOMEwork}/rtofs_obs_read.x read_ssh
if [[ -f ssh.txt ]]; then
mv ssh.txt sshab.txt
fi
fi

ls -l ${ocnqcpath}/${today}.${plat}
ln -sf ${ocnqcpath}/${today}.${plat} ssh.bin
${HOMEwork}/rtofs_obs_read.x read_ssh
if [[ -f ssh.txt ]]; then
cat ssh.txt >> sshab.txt
fi

mv sshab.txt ssh.txt
echo start NETCDF

${HOMEwork}/rtofs_ascii2iodav3.py -i ssh.txt -v absoluteDynamicTopography -o ./adt_${plat}_${YMDH}.nc

done # plat loop

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )

DHH=$(($DH-12))
YMDHm1d=$(date -ud "$date_YMDH + $DHH hours" +%Y%m%d%H )

DHm3h=$(($DH-3))
winstart=$(date -ud "$date_YMDH + $DHm3h hours" +%Y%m%d%H )

DHp3h=$(($DH+3))
winend=$(date -ud "$date_YMDH + $DHp3h hours" +%Y%m%d%H )

DH=$(($DH+6))

done # time loop

mv adt_*.nc NC/.

#fi  # SKIP

######################### convert RTOFS SSS into IODA v3 ############

DH=6
platlist=(sss)
ocnqcpath=${HOMEwork}/ocnqc/sss

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
today=${YMDH:0:8}00

YMDHm1d=$(date -ud "$date_YMDH - 19 hours" +%Y%m%d%H )
yesterday=${YMDHm1d:0:8}00

winstart=$(date -ud "$date_YMDH - 3 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 3 hours" +%Y%m%d%H )

while [ "$YMDH" -le "$END_YMDH" ]; do

today=${YMDH:0:8}00
yesterday=${YMDHm1d:0:8}00
echo $winstart $YMDH $winend

for plat in ${platlist[@]}; do

rm window.txt
echo ${winstart}0000 > window.txt
echo ${winend}0000 >> window.txt

rm sss.bin sss.txt
if [[ ${YMDH:8:2} == "00" ]]; then
ls -l ${ocnqcpath}/${yesterday}.${plat}
ln -sf ${ocnqcpath}/${yesterday}.${plat} sss.bin
${HOMEwork}/rtofs_obs_read.x read_sss
if [[ -f sss.txt ]]; then
mv sss.txt sssab.txt
fi
fi

ls -l ${ocnqcpath}/${today}.${plat}
ln -sf ${ocnqcpath}/${today}.${plat} sss.bin
${HOMEwork}/rtofs_obs_read.x read_sss
if [[ -f sss.txt ]]; then
cat sss.txt >> sssab.txt
fi

mv sssab.txt sss.txt
echo start NETCDF

${HOMEwork}/rtofs_ascii2iodav3.py -i sss.txt -v seaSurfaceSalinity -o ./sss_salinity_${YMDH}.nc

done # plat loop

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )

DHH=$(($DH-12))
YMDHm1d=$(date -ud "$date_YMDH + $DHH hours" +%Y%m%d%H )

DHm3h=$(($DH-3))
winstart=$(date -ud "$date_YMDH + $DHm3h hours" +%Y%m%d%H )

DHp3h=$(($DH+3))
winend=$(date -ud "$date_YMDH + $DHp3h hours" +%Y%m%d%H )

DH=$(($DH+6))

done # time loop

mv sss_salinity_*.nc NC/.

#fi  # SKIP
##################### END ###############################
 if [[ ! -d data ]]; then
   mkdir data
 fi
 mv *.bin *.txt ./data/.
