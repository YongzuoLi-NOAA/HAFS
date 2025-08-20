#!/bin/bash -l

echo "Yongzuo Li"

rm ../logs/*

## rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312121200 -t 3d-fgat
                                                                   
rocotorun  -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312121200 -v 10
rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db
squeue -l -u $USER

ls -l ../logs/*
more ../logs/mom6_forecast_xml_2023121212.err
more ../logs/mom6_forecast_xml_2023121212.out

exit

rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312121200 -t 3d-fgat
rocotorewind -w test_soca_workflow.xml -d test_soca_workflow.db -c 202312121200 -t mom6_forecast


