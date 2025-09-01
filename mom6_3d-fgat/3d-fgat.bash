#!/bin/bash -l
#SBATCH --job-name=3d-fgat
#SBATCH --account=cpcenso
#SBATCH --partition=batch
#SBATCH --qos=normal
#SBATCH --time=00:30:00
#SBATCH --nodes=12
#SBATCH --ntasks-per-node=40
#SBATCH --cpus-per-task=1
#SBATCH --cluster=c5
#SBATCH -o slurm-%x-%j.out
#SBATCH -e slurm-%x-%j.err

set -Eeuo pipefail
umask 022
set -x

module purge
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd
module use modulefiles
module load GDAS/gaeac5.intel
module -t list
ulimit -S -s unlimited
ulimit -c unlimited

# ---- Paths (adjust only if your layout differs) ----
RUN_DIR=${RUN_DIR:-${RUNBASE}/${ANA_TIME}/3d-fgat}

# refuse to delete if RUN_DIR isn't under your SCRATCH tree
if [[ "$RUN_DIR" == /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/*/3d-fgat ]]; then
  rm -rf -- "$RUN_DIR"
else
  echo "Refusing to rm dangerous RUN_DIR: $RUN_DIR" >&2
  exit 2
fi

mkdir -p "$RUN_DIR"
cd "$RUN_DIR"
echo YongzuoLI-NOAA
pwd

mkdir -p OUTPUT data_output RESTART

ln -sf ${HOMEBASE}/soca_fix/* .
ln -sf ${HOMEBASE}/obs .
ln -sf ${HOMEBASE}/forecast_mom6 .
ln -sf /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd/build/bin/gdas.x .

cp ${HOMEBASE}/soca_parm/3d-fgat.yml-tmp 3d-fgat.yml

###YMDH=2023120712
YMDH=${ANA_TIME}

TMP_YMDH=${YMDH:0:8}Z${YMDH:8:2}
TMP_DATE=$(date -ud "$TMP_YMDH")

YMDH00=$(date -ud "$TMP_DATE" +%Y%m%d%H)
YMDHM1=$(date -ud "$TMP_DATE - 24 hours" +%Y%m%d%H)
YMDHP1=$(date -ud "$TMP_DATE + 24 hours" +%Y%m%d%H)

echo ${YMDHM1} ${YMDH00} ${YMDHP1}

# create 3d-fgat.yml

cp ${HOMEBASE}/soca_parm/3d-fgat.yml-tmp 3d-fgat.yml

sed -i "s;YM1;${YMDHM1:0:4};g" 3d-fgat.yml
sed -i "s;MM1;${YMDHM1:4:2};g" 3d-fgat.yml
sed -i "s;DM1;${YMDHM1:6:2};g" 3d-fgat.yml

sed -i "s;Y00;${YMDH00:0:4};g" 3d-fgat.yml
sed -i "s;M00;${YMDH00:4:2};g" 3d-fgat.yml
sed -i "s;D00;${YMDH00:6:2};g" 3d-fgat.yml

sed -i "s;YP1;${YMDHP1:0:4};g" 3d-fgat.yml
sed -i "s;MP1;${YMDHP1:4:2};g" 3d-fgat.yml
sed -i "s;DP1;${YMDHP1:6:2};g" 3d-fgat.yml

# Let srun inherit the SBATCH layout
export OMP_NUM_THREADS=1
srun --export=ALL --cpu-bind=cores ./gdas.x soca variational ./3d-fgat.yml 2>&1 \
  | grep -v 'CRAYBLAS_WARNING' | tee 3d-fgat.out

# (3) update MOM.res.nc with analysis Temp, Salt, & ave_ssh for mom6_fcst task

# copy 3d-fgat first guess & analysis output
# data_output=${RUNBASE}/${ANA_TIME}/3d-fgat/data_output
#RUN_DIR=${RUN_DIR:-${RUNBASE}/${ANA_TIME}/mom6_fcst}
#cp -aL ${data_output}/ocn.3dvarfgat_pseudo.an.${YMD:0:4}-${YMD:4:2}-${YMD:6:2}T12:00:00Z.nc ocn.ana.nc
cp -aL data_output/ocn.3dvarfgat_pseudo.an.${YMDH00:0:4}-${YMDH00:4:2}-${YMDH00:6:2}T12:00:00Z.nc ocn.ana.nc
#MOMres_input=${RUNBASE}/${ANA_TIME}/3d-fgat/forecast_mom6
#cp -aL ${MOMres_input}/MOM.res.${ANA_TIME}.nc MOM.res.nc
cp -aL forecast_mom6/MOM.res.${ANA_TIME}.nc MOM.res.nc

# (1) rename variables and dimensions of (3d-fgat task) analysis model grid data

ncks -A -v Temp,Salt,ave_ssh ./ocn.ana.nc ./TS3D_SSH.nc
ncrename -d zaxis_1,Layer -d yaxis_1,lath -d xaxis_1,lonh ./TS3D_SSH.nc
ncrename -v zaxis_1,Layer -v yaxis_1,lath -v xaxis_1,lonh ./TS3D_SSH.nc

# (2) update first guess (forecast_mom6) MOM.res.nc with analysis
#     Temp,Salt,ave_ssh for forecast (mom6_fcst task) IC (MOM.res.nc)

ncks -A -v Time,Layer,lath,lonh ./MOM.res.nc ./TS3D_SSH.nc    # replace dim to be consistent
ncks -A -v Time,Temp,Salt,ave_ssh ./TS3D_SSH.nc ./MOM.res.nc  # update T, S, SSH from 3DVAR

#rm ./RESTART_IN/MOM.res.nc
mv ./MOM.res.nc ./RESTART/MOM.res.nc

# Finish updating MOM.res.nc

echo "3D-FGAT job finished at $(date)"

