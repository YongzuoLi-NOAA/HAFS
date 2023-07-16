#!/bin/bash 

export HOME3DVAR=/work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR

export socascience="/work2/noaa/marine/yli/JEDI/jedi-20230316/soca-science"

cd ${HOME3DVAR}/parm
ln -sf ${socascience}/configs/machine/machine.orion.gnu .

cd ${HOME3DVAR}/exec
ln -sf ${socascience}/build.gnu/bin/* .

cd ${HOME3DVAR}/fix
ln -sf /work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR_fix/* .

cd ${HOME3DVAR}/obs
ln -sf /work2/noaa/hwrf/save/yongzuo/MOM6_3DVAR_obs/* .

