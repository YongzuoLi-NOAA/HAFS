#!/bin/ksh
#PBS -e UPP.err
#PBS -o UPP.out
#PBS -V

# M
set -x

export YYYYMMDDHH=${startdate}
export TOP_DIR=/work/DEV/yongzuo/China

export DOMAINPATH=${TOP_DIR}/${YYYYMMDDHH}
export modelDataPath=${DOMAINPATH}/nmmb               # or nemsprd
export WORK_DIR=${DOMAINPATH}/upp

export POSTEXEC=${TOP_DIR}/upp_fix

mkdir ${WORK_DIR}
cd ${WORK_DIR}
mkdir ${fhr}
cd ${fhr}

export dyncore="NMB"
export inFormat="binarynemsio"
export outFormat="grib"

export startdate=${YYYYMMDDHH}
#export fhr=00
#export lastfhr=12
#export incrementhr=03

export domain_list="d01"
export RUN_COMMAND="mpirun -np ${UPPPROC} ${POSTEXEC}/unipost.exe "
export copygb_opt="lambert"
export tag=NMM
export tmmark=tm00
export MP_SHARED_MEMORY=yes
export MP_LABELIO=yes

ln -fs ${POSTEXEC}/ETAMPNEW_DATA nam_micro_lookup.dat
ln -fs ${POSTEXEC}/ETAMPNEW_DATA.expanded_rain hires_micro_lookup.dat

#time loop
export NEWDATE=$startdate
while [ $((10#${fhr})) -le $((10#${lastfhr})) ] ; do

fhr=`printf "%02i" ${fhr}`
NEWDATE=`${POSTEXEC}/ndate.exe +$((10#${fhr})) $startdate`
YY=`echo $NEWDATE | cut -c1-4`
MM=`echo $NEWDATE | cut -c5-6`
DD=`echo $NEWDATE | cut -c7-8`
HH=`echo $NEWDATE | cut -c9-10`

#domain loop
for domain in ${domain_list}
do
   dom_id=`echo "${domain}" | cut -d 'd' -f 2`
   inFileName=${modelDataPath}/nmmb_hst_${dom_id}_nio_00${fhr}h_00m_00.00s

cat > itag <<EOF
${inFileName}
${inFormat}
${YY}-${MM}-${DD}_${HH}:00:00
${tag}
EOF

 ln -fs ${POSTEXEC}/nmb_cntrl.parm fort.14
 ${RUN_COMMAND} > unipost_${domain}.${fhr}.out 2>&1
 mv NMBPRS${fhr}.${tmmark} NMBPRS_${domain}.${fhr}

   read nav < 'copygb_gridnav.txt' 
   export nav
   ${POSTEXEC}/copygb.exe -xg"${nav}" NMBPRS_${domain}.${fhr} nmbprs_${domain}.${fhr}
   mv *.${fhr} ../.
   cd ..
   rm -r ${fhr}

done #domain loop

fhr=$((10#${fhr}+$((${incrementhr}))))
NEWDATE=`${POSTEXEC}/ndate.exe +$((10#${fhr})) $startdate`
done # time loop

date
echo "End of Output Job"
exit
