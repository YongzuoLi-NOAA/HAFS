#!/bin/bash -l

YMDA=20241227
YMDB=20241231

cp -p driver_sbatch.bash-tmp driver_sbatch.bash
sed -i "s;YMDA;${YMDA};g" driver_sbatch.bash
sed -i "s;YMDB;${YMDB};g" driver_sbatch.bash

cp -p test_soca_workflow.xml-tmp test_soca_workflow.xml
sed -i "s;YMDA;${YMDA};g" test_soca_workflow.xml
sed -i "s;YMDB;${YMDB};g" test_soca_workflow.xml

sbatch ./driver_sbatch.bash

