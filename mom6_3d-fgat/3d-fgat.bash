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

mkdir -p ${WORKBASE}/${ANA_TIME}/3d-fgat
cd ${WORKBASE}/${ANA_TIME}/3d-fgat
pwd
mkdir -p OUTPUT data_output

#mkdir -p /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/${ANA_TIME}/3d-fgat
#cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/${ANA_TIME}/3d-fgat

ln -sf ${HOMEBASE}/soca_fix/* .
ln -sf ${HOMEBASE}/soca_parm/3d-fgat.yml-${ANA_TIME} 3d-fgat.yml
ln -sf ${HOMEBASE}/obs .
ln -sf ${HOMEBASE}/forecast_mom6 .
ln -sf /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd/build/bin/gdas.x .

# Let srun inherit the SBATCH layout
export OMP_NUM_THREADS=1
srun --export=ALL --cpu-bind=cores ./gdas.x soca variational ./3d-fgat.yml 2>&1 \
  | grep -v 'CRAYBLAS_WARNING' | tee 3d-fgat.out

echo "3D-FGAT job finished at $(date)"

