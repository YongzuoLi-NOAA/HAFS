#!/bin/bash -l
set -euo pipefail

cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/mom6_3d-fgat_rocoto/rocoto

### Example: daily cycles from 12Z 4/23/2024 → 12Z 5/31/2024

./run_rocoto_range.bash 202404231200 202405311200 24 \
  test_soca_workflow.xml test_soca_workflow.db

