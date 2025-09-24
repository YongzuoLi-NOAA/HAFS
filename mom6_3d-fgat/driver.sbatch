#!/bin/bash -l
#SBATCH -A cpcenso
#SBATCH -p batch
#SBATCH --clusters=c5
#SBATCH -t 8:00:00
#SBATCH -J rocoto_driver
#SBATCH -N 1
#SBATCH -o driver.%j.out
#SBATCH -e driver.%j.err

set -euo pipefail

## Insert ./go.bash here to drive ./run_rocoto_range.bash
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/mom6_3d-fgat_rocoto/rocoto
./run_rocoto_range.bash 202405271200 202407101200 24 \
  test_soca_workflow.xml test_soca_workflow.db

## sbatch driver.sbatch
## ChatGPT: bash ./go.bash 
## THIS file: driver.sbatch
