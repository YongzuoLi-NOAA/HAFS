#!/bin/bash

module purge
module use /work/noaa/da/role-da/spack-stack/modulefiles
module load miniconda/3.9.7
module load ecflow/5.8.4
module use /work/noaa/epic-ps/role-epic-ps/spack-stack/spack-stack-1.3.1/envs/unified-env/install/modulefiles/Core
module load stack-gcc/10.2.0
module load stack-openmpi/4.0.4
module load stack-python/3.9.7
module load soca-env
module load fms/release-jcsda

##. /work/noaa/da/kritib/soca-shared/soca_python-3.9/bin/activate
#. /work/noaa/da/kritib/soca-shared/spack-stack/soca_python-3.9/bin/activate
. /work2/noaa/jcsda/kritib/soca-shared/spack-stack/soca_python-3.9/bin/activate
ulimit -s unlimited

export MPIRUN=$(which srun)
export WORKLOAD_MANAGER=slurm
export JOB_OPTS="--exclusive"
