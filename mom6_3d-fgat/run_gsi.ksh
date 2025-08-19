#!/bin/ksh

# Yongzuo Get into GSI directory
  cd ${GSI_DIR}
  BYTE_ORDER=Big_Endian

# Link fixed files and CRTM coefficient files

  ln -sf ${GSI_FIX}/* .

# Link to the prepbufr data

  HH=$ST_HH
  PREPBUFR=${OBS_DIR}/gdas1.t${HH}z.prepbufr.nr
  ln -sf ${PREPBUFR} ./prepbufr

# copy over background field (it's modified by GSI so we can't link to it)

cp wrf_bkfile wrf_inout

# run GSI

  RUN_COMMAND="time mpirun -np ${GSIPROC} "
  ${RUN_COMMAND} ./gsi.exe > stdout 2>&1  

# Prepare NMMB Initial condition

  ln -sf wrf_inout wrfanl.${ANAL_TIME}

  mkdir ../nmmb

  if [ $HH -eq '00' ]||[ $HH -eq '06' ]||[ $HH -eq '12' ]||[ $HH -eq '18' ]; then
   ln -sf ${GSI_DIR}/wrfanl.${ANAL_TIME} ../nmmb/input_domain_01_nemsio
  else
   ln -sf ${GSI_DIR}/wrfanl.${ANAL_TIME} ../nmmb/restart_file_01_nemsio
  fi

#  run time error check
echo "The GSI  finished time is `date`."
exit 0
