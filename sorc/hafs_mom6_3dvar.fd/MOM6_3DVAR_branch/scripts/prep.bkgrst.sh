#!/bin/bash

# (C) Copyright 2020-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

set -e

cat << EOF

#================================================================================
#================================================================================
# prep.bkg_rst.sh
# link /work2/noaa/hwrf/scrub/yongzuo/HAFS_hfsa_mom6/2022092312/09L/forecast/
# RESTART/20220924.120000.MOM.res.nc to
# /work2/noaa/hwrf/scrub/yongzuo/MOM6_3DVAR/rst/2022092412/ctrl/MOM.res.nc
#================================================================================

EOF

# TCID=$3
# INIT=$2
# YMDH=$1
# echo prep.bkgrst ${YMDH}

INIT=$(date -ud "$BKG_INIT_DATE" +%Y%m%d%H )
YMDH=$(date -ud "$ANA_DATE" +%Y%m%d%H )

echo $TCID $INIT $YMDH

HAFS_hfsa_mom6=${WORKhafshome}/${INIT}/${TCID}/forecast/RESTART
BKGRST_DIR=${WORK3DVAR}/rst/${YMDH}/ctrl

# 1) Does a background already exist? If so exit early
if [[ -d "$BKGRST_DIR"  &&  $(ls $BKGRST_DIR/*.nc -1q 2>/dev/null | wc -l) -gt 0 ]]; then
    echo "Background already exists."
    echo " $BKGRST_DIR"
    echo "done with prep.bkgrst"
    exit 0
fi

mkdir -p ${BKGRST_DIR}

## ++++++++++ link from hfsa-mom6 workflow++++++++++++

ln -s ${HAFS_hfsa_mom6}/${YMDH:0:8}.${YMDH:8:2}0000.MOM.res_1.nc ${BKGRST_DIR}/MOM.res_1.nc
ln -s ${HAFS_hfsa_mom6}/${YMDH:0:8}.${YMDH:8:2}0000.MOM.res.nc ${BKGRST_DIR}/MOM.res.nc

echo "done with prep.bkgrst"

