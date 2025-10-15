#!/bin/bash -l

rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db

squeue -l -u $USER

ls -l ../logs/*

rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db
rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -v 10

rocotoboot -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -t mom6_fcst

rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312311200 -t mom6_fcst

ls -l /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/

