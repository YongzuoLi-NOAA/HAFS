#!/bin/sh
set -x
date

source /apps/lmod/lmod/init/sh

module purge
module use /work/noaa/da/role-da/spack-stack/modulefiles
module load miniconda/3.9.7
module load ecflow/5.8.4
module use /work/noaa/da/role-da/spack-stack/spack-stack-v1/envs/skylab-3.0.0-gnu-10.2.0/install/modulefiles/Core
module load stack-gcc/10.2.0
module load stack-openmpi/4.0.4
module load stack-python/3.9.7
module load soca-env/1.0.0
module load fms/release-jcsda

. /work/noaa/da/kritib/soca-shared/spack-stack/soca_python-3.9/bin/activate

ulimit -s unlimited

export MPIRUN=$(which srun)
export WORKLOAD_MANAGER=slurm
