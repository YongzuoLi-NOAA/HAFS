#!/bin/bash -l

echo "Yongzuo Li"

rm ../logs/*

rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312131200 -t mom6_forecast
rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312131200 -v 10
rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db
squeue -l -u $USER

ls -l ../logs/*
more ../logs/mom6_forecast_xml_2023121312.err
more ../logs/mom6_forecast_xml_2023121312.out

exit

rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312131200 -t 3d-fgat
rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312131200 -t mom6_forecast

ls -l /gpfs/f5/cpchso/scratch/Yongzuo.Li/SCRATCH/


