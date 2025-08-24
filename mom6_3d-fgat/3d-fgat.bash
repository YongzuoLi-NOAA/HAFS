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

echo "3D-FGAT job finished at $(date)"

