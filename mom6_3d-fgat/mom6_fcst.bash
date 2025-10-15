#!/bin/bash -l
# mom6_fcst.bash — UFS (DATM+CMEPS+MOM6+CICE6) forecast launcher for Gaea C5
# PET layout (for reference):
#   ATM  0–15   (16)    MED 16–31   (16)    OCN 32–131  (100)    ICE 132–155 (24)

set -Eeuo pipefail
umask 022

# ---- optional debug toggle ----
: "${DEBUG:=0}"
if [[ "$DEBUG" == "1" ]]; then set -x; fi

echo "=== MOM6 forecast start: $(date)"
echo "Node list: ${SLURM_JOB_NODELIST:-unset}"
echo "NTASKS: ${SLURM_NTASKS:-unset}  CPUS/Task: ${SLURM_CPUS_PER_TASK:-1}"
echo "ANA_TIME: ${ANA_TIME:-unset}"

# ---- required env from Rocoto/workflow ----
: "${SLURM_NTASKS:?SLURM_NTASKS is not set}"
: "${ANA_TIME:?ANA_TIME is not set}"
: "${RUNBASE:?RUNBASE is not set}"
: "${HOMEBASE:?HOMEBASE is not set}"
: "${START_TIME:?START_TIME is not set}"

# ---- working directory ----
RUN_DIR=${RUN_DIR:-${RUNBASE}/${ANA_TIME}/mom6_fcst}

# refuse to delete unless it's under your SCRATCH tree in the expected spot
if [[ "$RUN_DIR" == /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/*/mom6_fcst ]]; then
## KEEP keep rm -rf -- "$RUN_DIR"
  echo KEEP YONGZUO
else
  echo "Refusing to rm dangerous RUN_DIR: $RUN_DIR" >&2
  exit 2
fi

mkdir -p "$RUN_DIR"
cd "$RUN_DIR"
echo "PWD=$(pwd)"

### model_configure and datm.stream ###
YMDH=${ANA_TIME}
TMP_YMDH=${YMDH:0:8}Z${YMDH:8:2}
date_YMDH=$(date -ud "$TMP_YMDH")

cp "${HOMEBASE}/mom6_parm/datm.streams-tmp" datm.streams
YMD00=${YMDH:0:8}
YMDP1=$(date -ud "$date_YMDH + 1 day" +%Y%m%d)
YMDP2=$(date -ud "$date_YMDH + 2 day" +%Y%m%d)
YMDP3=$(date -ud "$date_YMDH + 3 day" +%Y%m%d)
YMDP4=$(date -ud "$date_YMDH + 4 day" +%Y%m%d)
YMDP5=$(date -ud "$date_YMDH + 5 day" +%Y%m%d)
sed -i "s;YMD00;${YMD00};g" datm.streams
sed -i "s;YMDP1;${YMDP1};g" datm.streams
sed -i "s;YMDP2;${YMDP2};g" datm.streams
sed -i "s;YMDP3;${YMDP3};g" datm.streams
sed -i "s;YMDP4;${YMDP4};g" datm.streams
sed -i "s;YMDP5;${YMDP5};g" datm.streams

cp "${HOMEBASE}/mom6_parm/model_configure-tmp" model_configure
YYYY=${YMDH:0:4}
MM=${YMDH:4:2}
DD=${YMDH:6:2}
HH=${YMDH:8:2}
sed -i "s;YYYY;${YYYY};g" model_configure
sed -i "s;MM;${MM};g" model_configure
sed -i "s;DD;${DD};g" model_configure
sed -i "s;HH;${HH};g" model_configure

 cp -p ${RUNBASE}/${YMD00}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMD00}.nc-orig
 cp -p ${RUNBASE}/${YMDP1}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMDP1}.nc-orig
 cp -p ${RUNBASE}/${YMDP2}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMDP2}.nc-orig
 cp -p ${RUNBASE}/${YMDP3}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMDP3}.nc-orig
 cp -p ${RUNBASE}/${YMDP4}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMDP4}.nc-orig
 cp -p ${RUNBASE}/${YMDP5}12/mom6_fcst/DATM_INPUT/atm.nc atm_${YMDP5}.nc-orig
 if [[ -f atm_${YMD00}.nc ]]; then
   rm atm_*.nc
 fi

 cp -p           atm_${YMD00}.nc-orig atm_${YMD00}.nc
 ncks -d time,2, atm_${YMDP1}.nc-orig atm_${YMDP1}.nc
 ncks -d time,2, atm_${YMDP2}.nc-orig atm_${YMDP2}.nc
 ncks -d time,2, atm_${YMDP3}.nc-orig atm_${YMDP3}.nc
 ncks -d time,2, atm_${YMDP4}.nc-orig atm_${YMDP4}.nc
 ncks -d time,2, atm_${YMDP5}.nc-orig atm_${YMDP5}.nc

### model_configure and datm.stream ###

# ---- stage run directory contents from template ----
CALbump_BASE=/gpfs/f5/cpchso/scratch/JieShun.Zhu/ng-godas/EXPrt.ice/CALbump2
if [[ ! -d ${CALbump_BASE}/SCRATCH/${ANA_TIME}/run.fcst ]]; then
  echo "FATAL: Missing ${CALbump_BASE}/SCRATCH/${ANA_TIME}/run.fcst" >&2
  exit 11
fi
# copy *contents* and dereference symlinks
## KEEP keep cp -aL "${CALbump_BASE}/SCRATCH/${ANA_TIME}/run.fcst/." "$RUN_DIR"/
export FHMAX=144         # run length in hours
export FHOUT=24           # archive/output interval (atmos/ocean timing stamps)
export FHOUT_HF=1        # (optional) high-freq early window
export FHMAX_HF=24       # (optional) how long to keep high-freq

# fresh restart dirs
rm -rf RESTART RESTART_IN RESTART_OUT || true
mkdir -p RESTART RESTART_IN RESTART_OUT

# ---- rpointer files (DATM/CMEPS/CICE) ----
rm -f rpointer.cpl rpointer.atm ./restart/ice.restart_file
cp "${HOMEBASE}/mom6_parm/rpointer.cpl-tmp" rpointer.cpl
cp "${HOMEBASE}/mom6_parm/rpointer.atm-tmp" rpointer.atm
cp "${HOMEBASE}/mom6_parm/ice.restart_file-tmp" ./restart/ice.restart_file

YMD=${ANA_TIME}
sed -i "s;YYYY;${YMD:0:4};g; s;MM;${YMD:4:2};g; s;DD;${YMD:6:2};g" rpointer.cpl
sed -i "s;YYYY;${YMD:0:4};g; s;MM;${YMD:4:2};g; s;DD;${YMD:6:2};g" rpointer.atm
sed -i "s;YYYY;${YMD:0:4};g; s;MM;${YMD:4:2};g; s;DD;${YMD:6:2};g" ./restart/ice.restart_file

# ---- executable ----
cp -aL "${HOMEBASE}/exec/fv3_datm_cdeps_intel.exe" .
test -x ./fv3_datm_cdeps_intel.exe || { echo "FATAL: fv3_datm_cdeps_intel.exe missing/not executable"; exit 12; }

# ---- modules: C5 runtime, spack NetCDF (avoid mixing HDF5 stacks) ----
module --ignore_cache purge
module refresh
module load PrgEnv-intel cray-mpich libfabric

# NetCDF C & Fortran needed by fv3_datm_cdeps_intel.exe (spack-provided)
module load netcdf-c/4.9.2 cray-hdf5/1.14.3.7  ##netcdf-fortran/4.6.1

# useful tools / IO libs if used
module load nco/5.1.9 eccodes/2.34.0

# DO NOT mix with Cray HDF5/PnetCDF unless you rebuild consistently
module unload cray-hdf5-parallel >/dev/null 2>&1 || true
module unload cray-parallel-netcdf >/dev/null 2>&1 || true

# optional site module collection (guarded)
module use /gpfs/f5/cpchso/scratch/Yongzuo.Li/3d-fgat_rocoto/rocoto/modulefiles || true
module load modules.fv3 || true

export FI_VERBS_PREFER_XRC=0
module -t list || true

# verify NetCDF runtime resolves before launch
if ! ldd ./fv3_datm_cdeps_intel.exe | egrep -q 'libnetcdf\.so\.19'; then
  echo "FATAL: libnetcdf.so.19 not resolved — check netcdf-c module" >&2
  ldd ./fv3_datm_cdeps_intel.exe | egrep -i 'netcdf|netcdff|hdf5|mpi|fabric' || true
  exit 18
fi
if ! ldd ./fv3_datm_cdeps_intel.exe | egrep -q 'libnetcdff\.so\.7'; then
  echo "FATAL: libnetcdff.so.7 not resolved — check netcdf-fortran module" >&2
  ldd ./fv3_datm_cdeps_intel.exe | egrep -i 'netcdf|netcdff|hdf5|mpi|fabric' || true
  exit 19
fi

# ---- clean logs of the *next* time stamp to avoid stale output collisions ----
next_TIME=$((START_TIME + 24*3600))
YMDH=$(date --date=@$next_TIME +"%Y%m%d%H")
ymdh=${YMDH:0:4}-${YMDH:4:2}-${YMDH:6:2}
echo "Next cycle ymdh=${ymdh}"
rm -f *"${ymdh}"* */*"${ymdh}"* PET*.ESMF_LogFile *.log || true

# ---- inject 3D-FGAT analysis into MOM.res.nc for ICs ----
data_output="${RUNBASE}/${ANA_TIME}/3d-fgat/data_output"
MOMres_input="${RUNBASE}/${ANA_TIME}/3d-fgat/forecast_mom6"

# sanity checks
test -s "${data_output}/ocn.3dvarfgat_pseudo.an.${YMD:0:4}-${YMD:4:2}-${YMD:6:2}T12:00:00Z.nc" \
  || { echo "FATAL: missing ocn.3dvarfgat_pseudo.an.*.nc" >&2; exit 21; }
test -s "${MOMres_input}/${ANA_TIME:0:8}.120000.MOM.res.nc" \
  || { echo "FATAL: missing ${MOMres_input}/${ANA_TIME:0:8}.120000.MOM.res.nc" >&2; exit 22; }

cp -aL "${data_output}/ocn.3dvarfgat_pseudo.an.${YMD:0:4}-${YMD:4:2}-${YMD:6:2}T12:00:00Z.nc" ocn.ana.nc
cp -aL "${MOMres_input}/${ANA_TIME:0:8}.120000.MOM.res.nc" MOM.res.nc

# (1) prepare T/S/SSH from analysis on model grid
if [[ -f TS3D_SSH.nc ]]; then
rm TS3D_SSH.nc
fi

ncks -A -v Temp,Salt,ave_ssh ./ocn.ana.nc ./TS3D_SSH.nc
ncrename -d zaxis_1,Layer -d yaxis_1,lath -d xaxis_1,lonh ./TS3D_SSH.nc
ncrename -v zaxis_1,Layer -v yaxis_1,lath -v xaxis_1,lonh ./TS3D_SSH.nc

# (2) merge dims/coords and inject into MOM.res.nc for initial condition
ncks -A -v Time,Layer,lath,lonh ./MOM.res.nc ./TS3D_SSH.nc
ncks -A -v Time,Temp,Salt,ave_ssh ./TS3D_SSH.nc ./MOM.res.nc

mkdir -p RESTART_IN
rm -f ./RESTART_IN/MOM.res.nc

# ---- NMC-method link rst/MOM.res.nc to extend fcst from 24-h to 48-h ----
# mv ./MOM.res.nc ./RESTART_IN/MOM.res.nc
ln -sf ${HOMEBASE}/forecast_mom6/${ANA_TIME:0:8}.120000.MOM.res.nc ./RESTART_IN/MOM.res.nc

# ---- launch UFS ----
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
ulimit -S -s unlimited

echo "Launching with srun -n ${SLURM_NTASKS}"
set +e
srun --cpu-bind=cores --hint=nomultithread -n "${SLURM_NTASKS}" ./fv3_datm_cdeps_intel.exe \
  2>&1 | tee -a mom6_fcst.log
rc=$?
set -e

# ---- basic failure digest ----
if [[ $rc -ne 0 ]]; then
  echo "ERROR: srun exited rc=$rc"
  head -n 200 PET000.ESMF_LogFile 2>/dev/null || true
  exit $rc
fi

# ---- provenance for reproducibility ----
mkdir -p ../logs
module -t list > "../logs/module_stack.mom6_fcst.${ANA_TIME}.txt" || true
ldd ./fv3_datm_cdeps_intel.exe | sort > "../logs/ldd.fv3_datm.${ANA_TIME}.txt" || true

# ---- NMC-method, no link here ----
# cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/mom6_3d-fgat_rocoto/forecast_mom6
# ln -sf ${RUNBASE}/${ANA_TIME}/mom6_fcst/RESTART/* .

echo "=== MOM6 forecast end: $(date)"

