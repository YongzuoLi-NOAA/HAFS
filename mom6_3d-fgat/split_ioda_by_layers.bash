#!/bin/bash -l

#tr -d ',' < layerz.txt > layerz_ws.txt
#exit

module purge
cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd
module use modulefiles
module load GDAS/gaeac5.intel

cd /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/2023120912/3d-fgat/data_output
python3 split_ioda_by_layers.py


