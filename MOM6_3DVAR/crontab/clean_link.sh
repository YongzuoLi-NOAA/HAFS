#!/bin/bash 

export HOME3DVAR=/work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR

cd ${HOME3DVAR}/exec
rm *

cd ${HOME3DVAR}/parm
rm machine.orion.gnu .

cd ${HOME3DVAR}/fix
rm *

cd ${HOME3DVAR}/obs
rm *

