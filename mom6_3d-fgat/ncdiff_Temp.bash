#!/bin/bash -l

rm bkg.Temp.nc
ncks -A -v Temp bkg/MOM.res.nc bkg.Temp.nc
rm ana.Temp.nc
ncks -A -v Temp ana/MOM.res.nc ana.Temp.nc
ncdiff -v Temp ana.Temp.nc bkg.Temp.nc diff_Temp.nc
exit


