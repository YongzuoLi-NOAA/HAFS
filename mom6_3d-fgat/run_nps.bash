#!/bin/bash

# KIf first cycle, Create all boco files for all cycles together 
# Otherwise, skip NPS

  HH=$ST_HH
  if [ $HH -eq '00' ]||[ $HH -eq '06' ]||[ $HH -eq '12' ]||[ $HH -eq '18' ]; then
   echo "Cold Start NPS Initialization at '$HH'"
  else
   echo "No need for NPS Initialization at '$HH'"
   exit 0
  fi

# Check the nps directory 

  if [ -d $NPS_DIR ];then
    echo "Enter NPS directory '$NPS_DIR'"
  else
    mkdir ${HOMEBASE}/${ANAL_TIME}
    mkdir $NPS_DIR
  fi

  cd $NPS_DIR/

# Link All NPS fix files

  ln -sf $NPS_FIX/* $NPS_DIR/.

# Link GFS grib files

  rm gfs.*
#2 files
  ln -sf $GFS_DIR/gfs.t${HH}z.pgrb2* $NPS_DIR/.
#history
  #ln -sf $GFS_DIR/gfs.0p25.${ANAL_TIME}.*.grib2 $NPS_DIR/.
#all
  #ln -sf $GFS_DIR/gfs* $NPS_DIR/.
  rm GRIBFILE*
  ./link_grib.csh gfs*
    
# Create nps namelist covering all cycles

  if [ $ST_md -ge '0308' ] && [ $ST_md -le '1101' ]; then
  START_TIME=$(($START_TIME-3600))
  fi
  ST_DATE=$(date --date=@$START_TIME +"%Y-%m-%d_%H:%M:%S")
  INTERVAL_SECONDS=10800
  boco_LENGTH=36
  END_TIME=$((START_TIME+boco_LENGTH*3600))
  ED_DATE=$(date --date=@$END_TIME +"%Y-%m-%d_%H:%M:%S")
  TPLFILE=${rocoto}/namelist.nps.tpl
  ncdump -h geo_nmb.d01.nc | sed 's/=//'| sed 's/DYN//'|sed 's/;//'|sed 's/f//'> head
  DX=`cat head |grep :DX|sed "s/:DX//"`
  DY=`cat head |grep :DY|sed "s/:DY//"`
  CEN_LAT=`cat head |grep :CEN_LAT|sed "s/:CEN_LAT//"`
  CEN_LON=`cat head |grep :CEN_LON|sed "s/:CEN_LON//"`
  WEST_EAST=`cat head |grep :WEST-EAST_PATCH_END_UNSTAG|sed "s/:WEST-EAST_PATCH_END_UNSTAG//"`
  SOUTH_NORTH=`cat head |grep :SOUTH-NORTH_PATCH_END_UNSTAG|sed "s/:SOUTH-NORTH_PATCH_END_UNSTAG//"`
  echo "$(eval "echo \"$(cat $TPLFILE)\"")"  > $NPS_DIR/namelist.nps

# Create all boco files for all cycles together at very begginning

  mpirun -np $SINGLEPROC ./ungrib.exe >& ungrib.log
  mpirun -np $SINGLEPROC ./metgrid.exe >& metgrid.log
  mpirun -np $SINGLEPROC ./nemsinterp.exe >& nemsinterp.log

# archive boco files for this & later cycles
   mkdir ${HOMEBASE}/boco
   mkdir ${boco_DIR}
   rm ${boco_DIR}/*
   echo $HH > ${boco_DIR}/cyc1start
   mv $NPS_DIR/boco* ${boco_DIR}/.

# prepare GSI background file if it is first cycle 

#  if [ $HH -eq '00' ]||[ $HH -eq '06' ]||[ $HH -eq '12' ]||[ $HH -eq '18' ]; then
    mkdir ../gsi
    ln -sf ${NPS_DIR}/input_domain_01_nemsio ../gsi/wrf_bkfile
#  fi

echo "The NPS finished time is `date`."
exit 0

