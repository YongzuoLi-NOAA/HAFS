#!/bin/bash

# Load modules
  module load pgi/14.10_64 
  module load mvapich2/1.9-r6338_pgi_64 
  module load netcdf/4.3.3.1_pgi_64 

# Get Linto NMMB directory

  cd $NMMB_DIR
  HH=$ST_HH

# link nmmb static files
  
  ln -sf ${NMMB_FIX}/* $NMMB_DIR/.

# link boco files

   rm boco* 
   cyc1start=`cat ${boco_DIR}/cyc1start`
   H1=${HH#0}
   T1=${cyc1start#0}
   N=$((H1-T1))
   i=0

   while [ $i -le 8 ]; do

    if [ $N -lt 10 ];then
    NN=0$N
    elif [ $N -ge 10 ];then
    NN=$N
    fi

#  ln -sf ${boco_DIR}/boco.00${NN} $NMMB_DIR/boco.000${i}

   i=$[$i+1]
   N=$[$N+1]

   done

ln -sf ${boco_DIR}/boco.00* $NMMB_DIR/.

# create nmmb configure file

  if [ $HH -eq '00' ]||[ $HH -eq '06' ]||[ $HH -eq '12' ]||[ $HH -eq '18' ]; then
   TSTART=0.
   RESTART=false
  else
   TSTART=$((H1-T1))
   RESTART=true
  fi
  NHOURS_FCST=36
  WEST_EAST=`cat ../nps/head |grep :WEST-EAST_PATCH_END_UNSTAG|sed "s/:WEST-EAST_PATCH_END_UNSTAG//"`
  SOUTH_NORTH=`cat ../nps/head |grep :SOUTH-NORTH_PATCH_END_UNSTAG|sed "s/:SOUTH-NORTH_PATCH_END_UNSTAG//"`
  
  TPLFILE=${rocoto}/configure_file_01.tpl
  echo "$(eval "echo \"$(cat $TPLFILE)\"")"  > $NMMB_DIR/configure_file_01
  ln -sf $NMMB_DIR/configure_file_01 $NMMB_DIR/model_configure

# runs NEMS.x

  mpirun -np $NMMBPROC ./NEMS.x >& nmmb.log 

# Prepare GSI background file for next cycle

  if [ $ST_md -ge '0308' ] && [ $ST_md -le '1101' ]; then
  START_TIME=$(($START_TIME-3600))  ###### Summer time
  fi
  next_LENGTH=1
  next_TIME=$((START_TIME+next_LENGTH*3600))
  next_DAY=$(date --date=@$next_TIME +"%Y%m%d%H")
  next_GSI=${HOMEBASE}/${next_DAY}/gsi
  mkdir ${HOMEBASE}/${next_DAY}
  mkdir $next_GSI
  ln -sf $NMMB_DIR/nmmb_rst_01_nio_0001h_00m_00.00s ${next_GSI}/wrf_bkfile

echo "The NMMB finished time is `date`."
exit 0

