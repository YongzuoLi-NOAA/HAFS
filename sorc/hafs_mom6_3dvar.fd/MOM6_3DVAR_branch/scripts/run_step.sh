#!/bin/bash

function run_step {
    [[ "$#" != 1 ]] && ( echo "ERROR: run_step must be called with one arg" && exit 1)
    printf "%-30s" "Running $1 ..."
    script=$SUBSCRIPTS_DIR/$1.sh
    log_file=$LOG_DIR_CYCLE/$1
    if [[ ! -f "$script" ]]; then
        printf "\nERROR unable to find file $script"
        exit 1
    fi
    (   export WORK_DIR=$SCRATCH_DIR_CYCLE/$1
        rm -rf $WORK_DIR
        mkdir -p $WORK_DIR
        cd $WORK_DIR

            time $script &> $log_file
    ) || { printf "ERROR in $1, exit code $?\n check $log_file"; exit 1; }
}

