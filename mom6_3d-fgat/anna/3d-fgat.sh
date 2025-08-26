#!/bin/sh

#SBATCH -o 3d-fgat.log
#SBATCH --job-name 3d-fgat
#SBATCH --account=cpcenso
#SBATCH --time=00:30:00
#SBATCH --qos normal
#SBATCH --partition=batch
#SBATCH --nodes=48-48
#SBATCH --tasks-per-node=10
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --cluster=c5

cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd
module use modulefiles
module load GDAS/gaeac5.intel

cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/3D_FGAT.MOM6

rm 3d-fgat.out.00*
rm -rf OUTPUT
mkdir -p data_output
mkdir -p OUTPUT

ulimit -S -s unlimited
## limit stacksize unlimited

srun --mem=0 --ntasks=480 --ntasks-per-node=10 --cpus-per-task=1 ./gdas.x soca variational ./3d-fgat.yml 3d-fgat.out

exit



