#!/bin/bash -l

# 8/29/2025

module purge
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd
module use modulefiles
module load GDAS/gaeac5.intel
export PYTHONPATH=$PYTHONPATH:/gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd/build/lib/python3.10

export HOMEwork=/gpfs/f5/cpchso/scratch/Yongzuo.Li/RTOFS2IODA_ObsQC
export HOMEncoda=${HOMEwork}/ncoda/ocnqc
cd ${HOMEwork}

START_YMDH=2023120112
  END_YMDH=2023121412

TMP_YMDH=${START_YMDH:0:8}Z${START_YMDH:8:2}
date_YMDH=$(date -ud "$TMP_YMDH")
echo $date_YMDH
DH=24

if [[ ! -d NC ]]; then
mkdir NC
fi

################### convert RTOFS profile into IODA v3 ##############
DH=24
platlist=(profile)
ocnqcpath=${HOMEncoda}/profile

YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
today=${YMDH:0:8}00

winstart=$(date -ud "$date_YMDH - 12 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 12 hours" +%Y%m%d%H )

echo $YMDH 
YMD=${YMDH:0:8}

while [ "$YMDH" -le "$END_YMDH" ]; do

today=${YMDH:0:8}00
echo $winstart $YMDH $winend

for plat in ${platlist[@]}; do

rm window.txt
echo ${winstart}00 > window.txt
echo ${winend}00 >> window.txt

####rm profile.bin profile.txt profile_all.txt

#ls -l ${ocnqcpath}/${today}.${plat}
#ln -sf ${ocnqcpath}/${today}.${plat} profile.bin

 ls -l ${HOMEwork}/2023//20231215/${today}.${plat}
ln -sf ${HOMEwork}/2023//20231215/${today}.${plat} profile.bin

${HOMEwork}/rtofs_obs_read.x read_profile

echo start NETCDF for ${YMDH}
./rtofs_ascii2iodav3.py -i profile.txt -v waterTemperature -o ./prof_insitu_${YMDH}.nc

done # platform loop

# update YMDH -> +${DH} on $date_YMDH
YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
TMP_YMDH=${YMDH:0:8}Z${YMDH:8:2}
date_YMDH=$(date -ud "$TMP_YMDH")
# Finish update date_YMDH

##  ------ This is next time $date_YMDH ------
winstart=$(date -ud "$date_YMDH - 12 hours" +%Y%m%d%H )
winend=$(date -ud "$date_YMDH + 12 hours" +%Y%m%d%H )

done # time loop

exit

mv prof_insitu_*.nc NC/.

exit

######################### convert RTOFS SSH into IODA v3 ############

DH=6
platlist=(ssh)
ocnqcpath=${HOMEncoda}/ssh

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
ocnqcpath=${HOMEncoda}/sss

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
x

echo "SSS" ${YMDH:0:8}00

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
 
${HOMEwork}/rtofs_obs_read.x sss_qc

echo start NETCDF

${HOMEwork}/rtofs_ascii2iodav3.py -i sss_qc.txt -v seaSurfaceSalinity -o ./sss_salinity_${YMDH}.nc

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
 mv *.bin ./data/.

