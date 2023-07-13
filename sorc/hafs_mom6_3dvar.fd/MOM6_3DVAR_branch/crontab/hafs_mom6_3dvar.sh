#!/bin/sh
##set -x
##date

YMDH=$(date -ud "$ANA_DATE" +%Y%m%d%H )

export SCRIPTS_DIR=${HOME3DVAR}/scripts
export SUBSCRIPTS_DIR=${SCRIPTS_DIR}

export LOG_DIR=${WORK3DVAR}/logs
export LOG_DIR_CYCLE=${LOG_DIR}/${YMDH}
mkdir -p ${LOG_DIR_CYCLE}

export SCRATCH_DIR_CYCLE=${WORK3DVAR}/SCRATCH/${YMDH}
mkdir -p ${SCRATCH_DIR_CYCLE}

cd ${HOME3DVAR}/crontab

# (1) Link static
 ${SCRIPTS_DIR}/prep.soca.sh > ${LOG_DIR_CYCLE}/prep.soca

# (2) Link bkg rst MOM_res.nc 
 ${SCRIPTS_DIR}/prep.bkgrst.sh > ${LOG_DIR_CYCLE}/prep.bkgrst

# (3) Link Obs
 ${SCRIPTS_DIR}/prep.obs.sh > ${LOG_DIR_CYCLE}/prep.obs

#exit

# (4) 3DVAR
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

