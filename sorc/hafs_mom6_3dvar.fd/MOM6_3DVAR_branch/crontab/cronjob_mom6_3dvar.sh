#!/bin/sh
##set -x
##date

export HOMEhafs=${HOMEhafs:-/work2/noaa/hwrf/yongzuo/HAFS}
source ${HOMEhafs}/ush/hafs_pre_job.sh.inc

export WORKhafshome=/work2/noaa/hwrf/scrub/yongzuo/HAFS_hfsa_mom6
export HOME3DVAR=/work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR
export WORK3DVAR=/work2/noaa/hwrf/scrub/yongzuo/MOM6_3DVAR

export TCID="09L"
INIT=2022092312
YMDH=2022092412

######## End of user edit ##########

BKG_INIT=${INIT:0:8}Z${INIT:8:2}
export BKG_INIT_DATE=$(date -ud "$BKG_INIT")

EXP_START_DATE=${YMDH:0:8}Z${YMDH:8:2}
CYCLE_START_DATE=$(date -ud "$EXP_START_DATE")
export ANA_DATE=$(date -ud "$CYCLE_START_DATE")

${HOME3DVAR}/crontab/hafs_mom6_3dvar.sh

echo "Done hafs_mom6_3dvar"

exit
