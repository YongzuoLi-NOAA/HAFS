#!/bin/bash

# (C) Copyright 2020-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

set -e

cat << EOF

#================================================================================
#================================================================================
# prep.obs.sh
# link /work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR/obs/2022/20220924/
#      sst_goes_2022092412.nc to
# /work2/noaa/hwrf/scrub/yongzuo/MOM6_3DVAR/SCRATCH/2022092412/obs/sst/
#      sst_goes_2022092412.nc
#================================================================================

EOF
 
YMDH=$(date -ud "$ANA_DATE" +%Y%m%d%H)
echo prep.obs ${YMDH}

### obs settings
source ${HOME3DVAR}/parm/exp.config
export obs_files_dir=${obs_src_dir}/${YMDH:0:4}/${YMDH:0:8}

# obs_vars: sst sss adt salt temp
for obs_var in $obs_vars; do

    obs_var_dir=${WORK3DVAR}/obs/${obs_var}
    rm -rf ${obs_var_dir}
    mkdir -p ${obs_var_dir}

#   platforms: goes metop npp jpss amsr ssh pfl
    tmpstr="${obs_var}_platforms"
    platforms="${!tmpstr}"       # !tmpstr indirect expansion.
    for platform in $platforms; do
        obs_file="${obs_var}_${platform}_${YMDH}.nc"
        if [[ -d $obs_files_dir && $(ls $obs_files_dir/${obs_file} -1q 2>/dev/null | wc -l) -gt 0 ]]; then
        echo "Obs file found $obs_files_dir/${obs_file}"
        ln -s ${obs_files_dir}/${obs_file} ${obs_var_dir}/.
        fi
    done

    # make sure obs_var_dir isn't empty
    if [[ $(ls $obs_var_dir/* -1q 2>/dev/null | wc -l) -eq 0 ]]; then
        rm -rf $obs_var_dir
    fi
done

echo "done with prep.obs"

