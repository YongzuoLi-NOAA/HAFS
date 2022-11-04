#!/bin/sh
# This script may be used to check if the Regression Test for the HAFS system
# passed or not. The User need to specify the HAFS code directory (HAFS_dir)
# (usually HOMEhafs) and output (HAFS_out) directories (usually CDSCRUB) below.
# The script lists the *.xml files under $HAFS_dir/rocoto directory and gets
# the different configuration names.
# The script looks for:
# 1. storm1.done 2. *hafs.trac.atcfunix.all 
# 3. SUCCEEDED for completion task

# Author: Mrinal Biswas DTC/NCAR
# Do not contact: biswas@ucar.edu

#set -x

HAFS_dir=${1:-$(dirname $(pwd))}

if [ Q$(which rocotostat) = 'Q' ]; then
  echo "Error: Make sure rocotostat and rocotorewind in the path"
  exit 1
fi

cd ${HAFS_dir}/rocoto

for file in *.xml; do

#  file_noext=`echo $file |cut -f1 -d '.'`
  file_noext=`echo $file |rev|cut -c 5- |rev`
  echo $file_noext
  storm_init=`echo $file|rev|cut -f1 -d'-'|cut -f2 -d '.'|rev`
  sid=`echo $file|rev|cut -f2 -d '-'|rev`
  subexpt=`echo ${file_noext}|rev|cut -f3 -d'-'|rev`
  HAFS_out=$(grep "ENTITY WORKhafs" $file | cut -d'"' -f 2 | cut -d'&' -f1)

  echo `pwd`
  echo "Running ${subexpt}-${sid}-${storm_init} configuration"
  rocotostat -d hafs-${subexpt}-${sid}-${storm_init}.db -w hafs-${subexpt}-${sid}-${storm_init}.xml

  if_complete=`rocotostat -d hafs-${subexpt}-${sid}-${storm_init}.db -w hafs-${subexpt}-${sid}-${storm_init}.xml|grep -e completion |grep -e SUCCEEDED|wc -l`
  storm1_done=${HAFS_out}/${subexpt}/com/${storm_init}/${sid}/storm1.done
  atcfunix=$(/usr/bin/find ${HAFS_out}/${subexpt}/com/${storm_init}/${sid} -type f -name "*hafs.trak.atcfunix.all")

  # Check if rocoto completion task ran successfully or not

  if [ $if_complete == "1" ] || [ $if_complete == "2" ]; then
    echo "ROCOTO SAYS COMPLETION TASK SUCCEEDED"
  else
    echo "ROCOTO SAYS COMPLETION TASK DID NOT SUCCEED"
  fi

  # Check the post and product log files

  if [ $if_complete == "1" ] || [ $if_complete == "2" ]; then
    post_log=`cat ${HAFS_out}/${subexpt}/${storm_init}/${sid}/hafs_atm_post.log|grep "post job done"|tail -1`
    prod_log=`cat ${HAFS_out}/${subexpt}/${storm_init}/${sid}/hafs_product.log|grep "product job done"|tail -1`
    if [[ $post_log == "post job done" ]]; then
      echo "POST RAN TILL COMPLETION"
    else
      echo "POST DID NOT RAN TILL COMPLETION"
    fi
    if [[ $prod_log == "product job done" ]]; then
      echo "PRODUCT RAN TILL COMPLETION"
    else
      echo "PRODUCT DID NOT RAN TILL COMPLETION"
    fi
  fi

  # Check storm1.done atcfunix and hafsprs.synoptic files

  if [[ -e ${storm1_done} && -e ${atcfunix} ]]; then
    echo "FOUND STORM1.DONE, TRACKER OUTPUT "
  else
    echo "STORM1.DONE, TRACKER OUTPUT DO NOT EXIST"
  fi

  # Check if everything passed

  if [ $if_complete == "1" ] || [ $if_complete == "2" ]; then
    if [[ -e ${storm1_done} && -e ${atcfunix} ]]; then
    if [[ $post_log == "post job done" ]]; then
    if [[ $prod_log == "product job done" ]]; then
      echo "REGRESSION TEST PASSED!! YAYYY!!"
    else
      echo "REGRESSION TEST FAILED!! IT'S NOT YOUR FAULT!!"
    fi
    fi
    fi
  fi

done

exit
