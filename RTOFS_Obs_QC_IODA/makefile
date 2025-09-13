##mv rtofs_obs_read.F90 rtofs_obs_read.F

ftn -O2 -fpp -traceback -fno-alias -fp-model strict -no-fma -ftz \
    -DLINUX -convert big_endian -assume byterecl \
    -extend-source -real-size 32 -i4 \
    -o rtofs_obs_read.x rtofs_obs_read.F

