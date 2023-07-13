#!/bin/bash

# (C) Copyright 2020-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

set -e

cat << EOF

#================================================================================
#================================================================================
# prep.soca.sh
#  link /work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR/fix/static/bump & 
#  soca_gridspec.nc to /work2/noaa/hwrf/scrub/yongzuo/MOM6_3DVAR/static/.
#================================================================================

EOF

SOCA_STATIC_DIR=${WORK3DVAR}/static
mkdir -p ${SOCA_STATIC_DIR}

# create static B / localization

if [[ -d ${SOCA_STATIC_DIR}/bump ]]; then
    echo "static B has already been initialized, skipping."
else
    ln -s ${HOME3DVAR}/fix/static/* ${SOCA_STATIC_DIR}/.
fi

echo "done with prep.soca"

