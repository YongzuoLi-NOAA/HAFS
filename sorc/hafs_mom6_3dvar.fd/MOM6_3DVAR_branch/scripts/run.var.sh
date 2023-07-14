#!/bin/bash

# (C) Copyright 2020-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

set -e

cat << EOF

#================================================================================
#================================================================================
# run.var.sh
#   Run either a 3DVAR or 3DEnVAR
#================================================================================

EOF

# function that converts a soca incr to something MOM6 is happy with
function socaincr2mom6 {
  incr=$1
  bkg=$2
  grid=$3
  incr_out=$4

  scratch=scratch_socaincr2mom6
  mkdir -p $scratch
  cd $scratch

  cp $incr inc.nc                   # TODO: use accumulated incremnet, not outerloop intermediates
  ncks -A -C -v h $bkg inc.nc       # Replace h incrememnt (all 0's) by h background (expected by MOM)
  ncrename -d zaxis_1,Layer inc.nc  # Rename zaxis_1 to Layer
  ncks -A -C -v Layer $bkg inc.nc   # Replace dimension-less Layer with dimensional Layer
  mv inc.nc inc_tmp.nc              # ... dummy copy
  ncwa -O -a Time inc_tmp.nc inc.nc # Remove degenerate Time dimension
  ncks -A -C -v lon $grid inc.nc    # Add longitude
  ncks -A -C -v lat $grid inc.nc    # Add latitude
  mv inc.nc $incr_out
}

YMDH=$(date -ud "$ANA_DATE" +%Y%m%d%H)
echo ${YMDH}

EXP_START_DATE=${YMDH:0:8}Z${YMDH:8:2}
CYCLE_START_DATE=$(date -ud "$EXP_START_DATE")
export ANA_DATE=$(date -ud "$CYCLE_START_DATE")
echo $ANA_DATE 

source ${HOME3DVAR}/parm/exp.config

export SOCA_STATIC_DIR=${HOME3DVAR}/fix/static
export SOCA_SCIENCE_BIN_DIR=${HOME3DVAR}/exec
export SOCA_BIN_DIR=${HOME3DVAR}/exec

export SCRATCH_DIR_CYCLE=${WORK3DVAR}/SCRATCH/${YMDH}

export ANARST_DIR=$SCRATCH_DIR_CYCLE/ana_rst/ctrl
export DIAGB_TMP_DIR=$SCRATCH_DIR_CYCLE/bmat
export INCR_TMP_DIR=$SCRATCH_DIR_CYCLE/incr/ctrl
export DIAG_TMP_DIR=$SCRATCH_DIR_CYCLE/diag
export OBS_DIR=$SCRATCH_DIR_CYCLE/obs
export OBS_OUT_CTRL_DIR=$SCRATCH_DIR_CYCLE/obs_out/ctrl
export OBS_ATM_OUT_CTRL_DIR=$SCRATCH_DIR_CYCLE/obs_atm_out/ctrl

MPIRUN=/opt/slurm/bin/srun
BKGRST_DIR=${WORK3DVAR}/rst/${YMDH}/ctrl

# skip running the var if it has already been run
if [[ -d "$ANARST_DIR" && $(ls $ANARST_DIR -1q | wc -l) -gt 0 ]]; then
  echo "VAR analysis has already been created at :"
  echo "  $ANARST_DIR"
  echo "done with VAR"
  exit 0
fi

WORK_DIR=${SCRATCH_DIR_CYCLE}/run.var
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}

# which mode are we running in?
case "$DA_MODE" in
  3dvar)
    echo "Doing 3DVAR"
    VAR_CFG_FILE=$SOCA_DEFAULT_CFGS_DIR/soca_3dvar.yaml
    ;;
  *)
    echo "ERROR, \$DA_MODE $DA_MODE cannot be handled by this script right now"
    exit 1
    ;;
esac

echo "ENTER run.var"
cd ${WORK_DIR}
pwd

ln -sf $SOCA_BIN_DIR/soca_{var,checkpoint_model,dirac}.x .
ln -sf $SOCA_SCIENCE_BIN_DIR/soca_var2dirac.x .

cp $SOCA_DEFAULT_CFGS_DIR/{fields_metadata,soca_checkpoint}.yaml .
cp $SOCA_DEFAULT_CFGS_DIR/obsop_name_map.yml .
cp $VAR_CFG_FILE var.yaml
ln -sf  $MODEL_CFG_DIR/* .

export FCST_RESTART=1
export FCST_LEN=6
export FCST_START_TIME=$ANA_DATE

./input.nml.sh > mom_input.nml

mkdir -p OUTPUT RESTART
mkdir -p INPUT

(cd INPUT && ln -sf $MODEL_DATA_DIR/* .)
ln -s $SOCA_STATIC_DIR/* .

(( DA_WINDOW_HW=FCST_LEN/2 ))
DA_WINDOW_START=$(date -ud "$ANA_DATE - $DA_WINDOW_HW hours" +"%Y-%m-%dT%H:%M:%SZ")
DA_ANA_DATE=$(date -ud "$ANA_DATE" +"%Y-%m-%dT%H:%M:%SZ")

echo $YMDH
echo $DA_WINDOW_HW $DA_WINDOW_START $DA_ANA_DATE

sed -i "s/__DA_WINDOW_START__/${DA_WINDOW_START}/g" var.yaml
sed -i "s/__DA_WINDOW_LENGTH__/PT${FCST_LEN}H/g" var.yaml
sed -i "s/__DA_ANA_DATE__/$DA_ANA_DATE/g" var.yaml

# Set domain and variables
domains='ocn'
dirac_vars='SSH T S'

sed -i "s;__DOMAINS__;$domains;g" var.yaml
sed -i "s;__DA_VARIABLES__;$DA_VARIABLES;g" var.yaml
sed -i "s;__DA_VARIABLES_OCN__;$DA_VARIABLES_OCN;g" var.yaml
sed -i "s;__DA_VARIABLES_ICE__;$DA_VARIABLES_ICE;g" var.yaml

sed -i "s;__DOMAINS__;$domains;g" soca_checkpoint.yaml
sed -i "s;__DA_VARIABLES__;$DA_VARIABLES;g" soca_checkpoint.yaml

# prepare the __OBSERVATIONS__ section of the config yaml
echo "Preparing individual observations:"
touch obs.yaml

# obs_vars: sst sss adt salt temp
for obs_var in $obs_vars; do
    # if obs directory doesn't exist, skipp this ob
    [[ ! -d $OBS_DIR/$obs_var ]] && continue

    # if obs directory is empty, skip
    [ "$(ls -A $OBS_DIR/$obs_var/)" ] || continue

    tmpstr="${obs_var}_platforms"
    platforms=${!tmpstr}           # indirect expansion

    # platforms: goes metop npp jpss amsr ssh pfl
    for platform in ${platforms}; do
        mkdir -p obs_out/${obs_var}_${platform}
        (
         cat $SOCA_DEFAULT_CFGS_DIR/obs/${obs_var}_${platform}.yaml > ob.tmp

         tmpl_fin="\$(experiment_dir)\/{{current_cycle}}\/${obs_var}_${platform}.{{window_begin}}.nc4"
         tmpl_fout="\$(experiment_dir)\/{{current_cycle}}\/\$(experiment).${obs_var}_${platform}.{{window_begin}}.nc4"
         obs_file=${OBS_DIR}/${obs_var}/${obs_var}_${platform}_${YMDH}.nc
         sed -i "s;$tmpl_fin;${obs_file};g" ob.tmp
         sed -i "s;$tmpl_fout;obs_out/${obs_var}_${platform}/${obs_var}_${platform}.nc;g" ob.tmp

         cat ob.tmp >> obs.yaml
        )
    done
done

sed -i "s/^/    /g" obs.yaml
sed -i $'/__OBSERVATIONS__/{r obs.yaml\nd}' var.yaml

# prepare background
mkdir -p Data
ln -sf $BKGRST_DIR bkg
ln -s bkg RESTART_IN

# run the var
export OOPS_TRACE=0
export OMP_NUM_THREADS=1
$MPIRUN ./soca_var.x var.yaml

# diagnose the B-matrix
if [[ "$DA_DIAGB_ENABLED" == [yYtT1] ]]; then

   for v in SSH T S ; do
     # create yaml file for dirac
     ./soca_var2dirac.x -v $v -o dirac.yaml \
                      -l 1 \
                      -s $DA_DIAGB_DIRAC_STEP \
                      -i var.yaml \
                      -d $domains \
                      -a "$DA_VARIABLES" \
                      -t "$DA_ANA_DATE"
     # apply B to diracs
     $MPIRUN ./soca_dirac.x dirac.yaml
  done

  # move files related to B
  mkdir -p $DIAGB_TMP_DIR
  shopt -s nullglob # enable nullglob

  for f in Data/*.{loc,dirac}*.nc
  do
    echo $f
    mv $f $DIAGB_TMP_DIR
  done

  shopt -u nullglob # disable nullglob

fi

# move outerloop increment files
mkdir -p $INCR_TMP_DIR
mv Data/*.var.iter* $INCR_TMP_DIR

# Prepare increment for MOM6 iau
if [[ "$DA_OCN_IAU" =~ [yYtT1] ]]; then
    # TODO: make sure it works when io layout is other than 1,1
    ( socaincr2mom6 `ls $INCR_TMP_DIR/ocn*.var.iter*` $BKGRST_DIR/MOM.res.nc `readlink soca_gridspec.nc` $INCR_TMP_DIR/inc.nc )
fi

# perform checkpointing
# Ocean
ln -sf Data/ocn.3dvar.an*.nc checkpoint_ana.nc

# Dump ocean analysis into MOM6 restart
if [[ "$DA_CHKPT_WITH_MODEL" =~ [yYtT1] ]]; then
   # Use MOM6 to checkpoint
   $MPIRUN ./soca_checkpoint_model.x soca_checkpoint.yaml
else
   # Simply dump ocean analysis in restarts (necessary when restarts are "dynamic_symmetric")
   cp $SOCA_DEFAULT_CFGS_DIR/soca_checkpoint_regional.yaml .
   $SOCA_SCIENCE_BIN_DIR/soca_domom6_action.py checkpoint
fi

# move this to a directory inside the SCRATCH directory
mkdir -p $ANARST_DIR

if ! [[ "$DA_OCN_IAU" =~ [yYtT1] ]]; then
   mv RESTART/* $ANARST_DIR/
fi

for f in $BKGRST_DIR/*; do
    f2=$(basename $f)
    [[ ! -f $ANARST_DIR/$f2 ]] && ln -s $f $ANARST_DIR/
done

mkdir -p $OBS_OUT_CTRL_DIR
mv obs_out/* $OBS_OUT_CTRL_DIR

echo "done with VAR"

