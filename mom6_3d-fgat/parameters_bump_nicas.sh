#!/bin/sh

#SBATCH -o bump_nicas.log
#SBATCH --job-name bump_nicas
#SBATCH --account=cpcenso
#SBATCH --time=08:00:00
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

cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/BUMP_NICAS

rm bump_nicas.out.00* bump_nicas.out
rm -rf OUTPUT; mkdir -p data_output OUTPUT

ulimit -S -s unlimited
## limit stacksize unlimited

srun --mem=0 --ntasks=480 --ntasks-per-node=10 --cpus-per-task=1 ./gdas_soca_error_covariance_toolbox.x ./parameters_bump_nicas.yml bump_nicas.out

exit



