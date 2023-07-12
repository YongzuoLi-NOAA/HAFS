#!/bin/sh
##set -x
##date

export HOME3DVAR=/work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR_v1
export WORK3DVAR=/work2/noaa/hwrf/scrub/yongzuo/MOM6_3DVAR_v1

TCID=09L
INIT=2022092312
YMDH=2022092412

export HAFS_hfsa_mom6=/work2/noaa/hwrf/scrub/yongzuo/HAFS_hfsa_mom6/${INIT}/${TCID}/forecast/RESTART

######## End of user edit ##########

EXP_START_DATE=${YMDH:0:8}Z${YMDH:8:2}
CYCLE_START_DATE=$(date -ud "$EXP_START_DATE")
export ANA_DATE=$(date -ud "$CYCLE_START_DATE")

export SCRIPTS_DIR=${HOME3DVAR}/scripts
export SUBSCRIPTS_DIR=${SCRIPTS_DIR}

export LOG_DIR=${WORK3DVAR}/logs
export LOG_DIR_CYCLE=${LOG_DIR}/${YMDH}
mkdir -p ${LOG_DIR_CYCLE}

export SCRATCH_DIR_CYCLE=${WORK3DVAR}/SCRATCH/${YMDH}
mkdir -p ${SCRATCH_DIR_CYCLE}

cd ${HOME3DVAR}/crontab

# (1) Link static
## ${SCRIPTS_DIR}/prep.soca.sh > ${LOG_DIR_CYCLE}/prep.soca

# (2) Link bkg rst MOM_res.nc 
## ${SCRIPTS_DIR}/prep.bkgrst.sh ${YMDH} ${INIT} ${TCID} > ${LOG_DIR_CYCLE}/prep.bkgrst

# (3) Link Obs
 ${SCRIPTS_DIR}/prep.obs.sh > ${LOG_DIR_CYCLE}/prep.obs

# (4) 3DVAR
export SOCA_SCIENCE_DIR=/work2/noaa/marine/yli/JEDI/jedi-20230316/soca-science
source ${HOME3DVAR}/parm/machine.orion.gnu
source ${HOME3DVAR}/parm/exp.config

rm -rf   ${WORK3DVAR}/SCRATCH/${YMDH}/run.var
mkdir -p ${WORK3DVAR}/SCRATCH/${YMDH}/run.var

# submit this script via SLURM
opt=""
JOB_OPTS=${JOB_OPTS:-" "}
JOB_QOS=${JOB_QOS:-" "}
JOB_PARTITION=${JOB_PARTITION:-" "}
JOB_NPES=${JOB_NPES:-" "}

[[ "$JOB_OPTS" != " " ]] && opt="$opt $JOB_OPTS"
[[ "$JOB_QOS" != " " ]] && opt="$opt --qos=$JOB_QOS"
[[ "$JOB_PARTITION" != " " ]] && opt="$opt --partition=$JOB_PARTITION"
[[ "$JOB_NPES" != " " ]] && opt="$opt --ntasks=$JOB_NPES"
echo /opt/slurm/bin/sbatch $opt --time=$JOB_TIME -A $JOB_ACCT -J $JOB_NAME \
     -o ${LOG_DIR_CYCLE}/run.var $SCRIPTS_DIR/run.var.sh

/opt/slurm/bin/sbatch $opt --time=$JOB_TIME -A $JOB_ACCT -J $JOB_NAME \
   -o ${LOG_DIR_CYCLE}/run.var $SCRIPTS_DIR/run.var.sh

exit

