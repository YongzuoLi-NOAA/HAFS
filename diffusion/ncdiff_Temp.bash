#!/bin/bash -l

YMDH=2023121012
mkdir -p ana bkg
runbase=/gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/${YMDH}/3d-fgat

#cd bkg
#ln -sf  ${runbase}/forecast_mom6/MOM.res.${YMDH}.nc .
#cp -p MOM.res.${YMDH}.nc MOM.res.nc

#cd ../ana
#ln -sf ${runbase}/RESTART/MOM.res.nc MOM.res.nc-orig
#cp -p MOM.res.nc-orig MOM.res.nc

#exit

rm bkg.Temp.nc
ncks -A -v Temp bkg/MOM.res.nc bkg.Temp.nc
rm ana.Temp.nc
ncks -A -v Temp ana/MOM.res.nc ana.Temp.nc
ncdiff -v Temp ana.Temp.nc bkg.Temp.nc diff_Temp.nc

exit


