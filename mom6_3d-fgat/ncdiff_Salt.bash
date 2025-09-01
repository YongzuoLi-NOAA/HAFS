#!/bin/bash -l

rm bkg.Salt.nc
ncks -A -v Salt bkg/MOM.res.nc bkg.Salt.nc
rm ana.Salt.nc
ncks -A -v Salt ana/MOM.res.nc ana.Salt.nc
ncdiff -v Salt ana.Salt.nc bkg.Salt.nc diff_Salt.nc
exit

