#!/bin/sh
##set -x
##date

## For rocoto rewind

## export HOME3DVAR=${HOMEhafs}/MOM6_3DVAR
## export WORK3DVAR=${WORKhafs}/MOM6_3DVAR

## YMDH=${CDATE:0:10}
## TMP_DATE=${YMDH:0:8}Z${YMDH:8:2}
## export ANA_DATE=$(date -ud "$TMP_DATE")

## CYCLE_INTERVAL=24
## INIT=$(date -ud "$ANA_DATE - ${CYCLE_INTERVAL} hours" +%Y%m%d%H )
## TCID=09L
## export BKGRST_INPUT_DIR=/work2/noaa/hwrf/scrub/yongzuo/HAFS_hfsa_mom6/${INIT}/${TCID}/forecast/RESTART

## End of rocoto rewind

YMDH=$(date -ud "$ANA_DATE" +%Y%m%d%H )

export SCRIPTS_DIR=${HOME3DVAR}/scripts

export LOG_DIR=${WORK3DVAR}/logs
mkdir -p ${LOG_DIR}

export OUTPUT_DIR=${WORK3DVAR}/output
mkdir -p ${OUTPUT_DIR}

cd ${HOME3DVAR}/crontab

# (1) Link static
 ${SCRIPTS_DIR}/prep.soca.sh > ${LOG_DIR}/prep.soca

# (2) Link bkg rst MOM_res.nc 
 ${SCRIPTS_DIR}/prep.bkgrst.sh > ${LOG_DIR}/prep.bkgrst

# (3) Link Obs
 ${SCRIPTS_DIR}/prep.obs.sh > ${LOG_DIR}/prep.obs

# (4) 3DVAR
 source ${HOME3DVAR}/parm/machine.orion.gnu
 source ${HOME3DVAR}/parm/exp.config

 $SCRIPTS_DIR/run.var.sh > ${LOG_DIR}/run.var

