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
RUN_BASE=${RUN_BASE:-/gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH}
RUNDIR=${RUNDIR:-${RUN_BASE}/${ANA_TIME}/forecast}
EXE=${EXE:-${RUNDIR}/fv3.exe}
### Yongzuo Li EXE=${EXE:-${RUNDIR}/fv3_datm_cdeps_intel.exe}

echo "RUNDIR: ${RUNDIR}"
cd "${RUNDIR}"

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
rm -f PET*.ESMF_LogFile atm.log mediator.log logfile.* run.fcst.stdout.log || true
rm -rf OUTPUT data_output
mkdir -p OUTPUT data_output

### CALbump_BASE=/gpfs/f5/cpchso/scratch/JieShun.Zhu/ng-godas/EXPrt.ice/CALbump
### cp -r ${CALbump_BASE}/SCRATCH/2023121212/run.fcst/* .
### cp ${CALbump_BASE}/SCRATCH/2023121212/ana_rst/ctrl/ice.restart_file
### cp ${CALbump_BASE}/rst/2023121212/ctrl/* .

# ---- Sanity checks ----
[[ -x "${EXE}" ]] || { echo "ERROR: missing exe ${EXE}"; exit 2; }

echo "=== MPI/lib check ==="
ldd "${EXE}" | egrep -i 'mpi|esmf|netcdf|pio' || true

# ---- Launch ----
echo "Launching with srun -n ${SLURM_NTASKS}"
set +e

## Yongzuo Li
cp -p ufs.configure-Yongzuo.Li ufs.configure
## Yongzuo Li

srun --cpu-bind=cores --hint=nomultithread -n "${SLURM_NTASKS}" "${EXE}" 2>&1 | tee -a run.fcst.stdout.log
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "ERROR: srun exited rc=$rc"
  head -n 120 PET000.ESMF_LogFile 2>/dev/null || true
  exit $rc
fi

echo "=== MOM6 forecast end: $(date)"

