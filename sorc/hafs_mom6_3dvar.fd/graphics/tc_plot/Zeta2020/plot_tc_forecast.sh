#!/bin/bash

module load ncl

tcname=Zeta

#yyyymmddhh=2020102606
for yyyymmddhh in 2020102418 2020102500 2020102506 2020102512 2020102518 2020102600 2020102606; do

cd ${yyyymmddhh}

cp ../scripts/Hurricane_track.ncl.tmp    Hurricane_track.ncl
cp ../scripts/Hurricane_Vmax_time.py.tmp Hurricane_Vmax_time.py
cp ../scripts/Hurricane_Pmin_time.py.tmp Hurricane_Pmin_time.py

sed -i "s;YYYYMMDDHH;${yyyymmddhh};g" Hurricane_track.ncl
sed -i "s;YEAR;${yyyymmddhh:0:4};g"   Hurricane_track.ncl
sed -i "s;TCNAME;${tcname};g"         Hurricane_track.ncl

sed -i "s;YYYYMMDDHH;${yyyymmddhh};g" Hurricane_Vmax_time.py
sed -i "s;YEAR;${yyyymmddhh:0:4};g"   Hurricane_Vmax_time.py
sed -i "s;TCNAME;${tcname};g"         Hurricane_Vmax_time.py

sed -i "s;YYYYMMDDHH;${yyyymmddhh};g" Hurricane_Pmin_time.py
sed -i "s;YEAR;${yyyymmddhh:0:4};g"   Hurricane_Pmin_time.py
sed -i "s;TCNAME;${tcname};g"         Hurricane_Pmin_time.py

ncl Hurricane_track.ncl
python3 Hurricane_Vmax_time.py
python3 Hurricane_Pmin_time.py

cd -

done

