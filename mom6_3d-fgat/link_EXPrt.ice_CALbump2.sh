#!/bin/sh

#rstHome=/gpfs/f5/cpchso/scratch/JieShun.Zhu/ng-godas/EXPrt.ice/CALbump/rst/
rstHome=/gpfs/f5/cpchso/scratch/JieShun.Zhu/ng-godas/EXPrt.ice/CALbump2/rst/

workHome=/gpfs/f5/cpchso/scratch/Yongzuo.Li/mom6_3d-fgat_rocoto/forecast_mom6

cd ${workHome}

## START_YMDH=2024060112
##  END_YMDH=2024123112

START_YMDH=2025010112
  END_YMDH=2025013112

TMP_YMDH=${START_YMDH:0:8}Z${START_YMDH:8:2}
date_YMDH=$(date -ud "$TMP_YMDH")
YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
DH=24

while [ "$YMDH" -le "$END_YMDH" ]; do

echo $YMDH
ln -sf ${rstHome}/${YMDH}/ctrl/MOM.res.nc MOM.res.${YMDH}.nc

YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
TMP_YMDH=${YMDH:0:8}Z${YMDH:8:2}
DH=$(($DH+24))

done # time loop

exit

