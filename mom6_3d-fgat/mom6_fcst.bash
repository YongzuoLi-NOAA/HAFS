#!/bin/bash -l
# forecast.sh — UFS (DATM+CMEPS+MOM6+CICE6) with explicit ICE PETs and runSeq
# PET layout:
#   ATM  0–15   (16)
#   MED 16–31   (16)
#   OCN 32–131  (100)
#   ICE 132–155 (24)

set -euo pipefail

echo "=== MOM6 forecast start: $(date)"
echo "Node list: ${SLURM_JOB_NODELIST:-unset}"
echo "NTASKS: ${SLURM_NTASKS:-unset}  CPUS/Task: ${SLURM_CPUS_PER_TASK:-1}"
echo "ANA_TIME: ${ANA_TIME:-unset}"

: "${SLURM_NTASKS:?SLURM_NTASKS is not set}"
: "${ANA_TIME:?ANA_TIME is not set}"

# ---- Paths (adjust only if your layout differs) ----
RUN_DIR=${RUN_DIR:-${WORKBASE}/${ANA_TIME}/forecast}
echo "RUN_DIR: ${RUN_DIR}"
mkdir ${RUN_DIR}
cd "${RUN_DIR}"

CALbump_BASE=/gpfs/f5/cpchso/scratch/JieShun.Zhu/ng-godas/EXPrt.ice/CALbump
cp -r ${CALbump_BASE}/SCRATCH/${ANA_TIME}/run.fcst/* .

rm rpointer.cpl rpointer.atm ./restart/ice.restart_file
cp ${HOMEBASE}/mom6_parm/rpointer.cpl-${ANA_TIME} rpointer.cpl
cp ${HOMEBASE}/mom6_parm/rpointer.atm-${ANA_TIME} rpointer.atm
cp ${HOMEBASE}/mom6_parm/ice.restart_file-${ANA_TIME} ./restart/ice.restart_file
cp ${HOMEBASE}/exec/fv3_datm_cdeps_intel.exe .

# ---- Quick modules/env (matches your earlier env) ----
module purge
module use /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd/modulefiles
module load GDAS/gaeac5.intel
module use /gpfs/f5/cpchso/scratch/Yongzuo.Li/3d-fgat_rocoto/rocoto/modulefiles
module load modules.fv3
module load nco
module -t list || true

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
ulimit -S -s unlimited

# ---- Clean logs / dirs ----
next_TIME=$((START_TIME+24*3600))
YMDH=$(date --date=@$next_TIME +"%Y%m%d%H")
ymdh=${YMDH:0:4}-${YMDH:4:2}-${YMDH:6:2}
echo ${ymdh}
ls -l *${ymdh}* */*${ymdh}*
rm *${ymdh}* */*${ymdh}*
rm -rf RESTART; mkdir RESTART
rm -f PET*.ESMF_LogFile *.log || true

# ---- Launch ----
echo "Launching with srun -n ${SLURM_NTASKS}"
set +e

srun --cpu-bind=cores --hint=nomultithread -n "${SLURM_NTASKS}" ./fv3_datm_cdeps_intel.exe \
       2>&1 | tee -a forecast.log
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "ERROR: srun exited rc=$rc"
  head -n 120 PET000.ESMF_LogFile 2>/dev/null || true
  exit $rc
fi

echo "=== MOM6 forecast end: $(date)"

