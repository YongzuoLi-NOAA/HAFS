#!/bin/bash -l

rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db
rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -v 10
rocotoboot
rocotoboot -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -t mom6_fcst
rocotorewind
rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -t mom6_fcst

squeue -l -u $USER

rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db

ls -l ../logs/*

ls -l /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/

