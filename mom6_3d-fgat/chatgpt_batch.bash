#!/bin/bash
#SBATCH -J bump_nicas
#SBATCH -o bump_nicas.log
#SBATCH --account=cpcenso
#SBATCH --time=08:00:00
#SBATCH --qos=normal
#SBATCH --partition=batch
#SBATCH --nodes=12
#SBATCH --ntasks-per-node=36
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --cluster=c5

set -euo pipefail

# Go to gdas.cd so "module use modulefiles" points to the right tree
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd
echo "CWD after cd to gdas.cd: $(pwd)"

module purge
module load PrgEnv-intel/8.5.0
module load craype/2.7.30
module load cray-mpich/8.1.28
module use modulefiles
module load GDAS/gaeac5.intel
module list

# Return to your run directory
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/BUMP_NICAS
echo "CWD before run: $(pwd)"

rm -f bump_nicas.out.00* bump_nicas.out || true
rm -rf OUTPUT; mkdir -p data_output OUTPUT

ulimit -S -s unlimited
export FI_VERBS_PREFER_XRC=0
export MPICH_MAX_THREAD_SAFETY=funneled

echo "Executable link deps:"
ldd ./gdas_soca_error_covariance_toolbox.x | egrep -i 'mpi|ofi|cxi|pmi|slurm|fabric' || true

# Launcher: omit --mpi (or switch to --mpi=pmi2 if your site requires it)
srun --kill-on-bad-exit=1 --distribution=block:block --hint=nomultithread \
     ./gdas_soca_error_covariance_toolbox.x ./parameters_bump_nicas.yml bump_nicas.out

