#!/bin/bash

python_dir=/work/noaa/marine/yli/soca-shared/soca-diagnostics

tcname=Zeta2020
#mkdir PNG
(cd PNG; rm *.png; ln -s ../../2020*/*.png .)
#exit

mkdir GIF
mkdir images

mv PNG/*10mVmax.png images/.
gif_path=${tcname}_10mVmax.gif
python3 ${python_dir}/mkmovie.py -o ${gif_path}
mv images/* PNG/.
rm ~/*.gif ~/*.png
cp *gif ~/.
mv *.gif GIF/.
#exit

mv PNG/*Pmin.png images/.
gif_path=${tcname}_Pmin.gif
python3 ${python_dir}/mkmovie.py -o ${gif_path}
mv images/* PNG/.
cp *gif ~/.
mv *.gif GIF/.
#exit

mv PNG/*track.png images/.
gif_path=${tcname}_track.gif
python3 ${python_dir}/mkmovie.py -o ${gif_path}
mv images/* PNG/.
cp *gif ~/.
mv *.gif GIF/.
exit

