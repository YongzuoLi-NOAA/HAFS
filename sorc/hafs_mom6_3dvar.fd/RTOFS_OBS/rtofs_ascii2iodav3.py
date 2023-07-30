#!/usr/bin/env python3

from __future__ import print_function
import argparse
import netCDF4 as nc
from datetime import datetime, timedelta
import numpy as np
import os

import pyiodaconv.ioda_conv_engines as iconv
from pyiodaconv.orddicts import DefaultOrderedDict

from warnings import filterwarnings
filterwarnings(action='ignore', category=DeprecationWarning, message='`np.bool` is a deprecated alias')

locationKeyList = [
    ("latitude", "float"),
    ("longitude", "float"),
    ("dateTime", "string"),
]

locationKeyListpfl = [
    ("latitude", "float"),
    ("longitude", "float"),
    ("depth", "float"),
    ("dateTime", "string")
]

GlobalAttrs = {}

DimDict = { }

VarDims = {
	" ": ['nlocs']
}

class marine(object):
    def __init__(self, filename, varname):
        self.filename = filename
        self.varname = varname
        self.varDict = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.metaDict = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.data = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.var_mdata = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.units = {}
        self._read()

    # Open input file and read relevant info
    def _read(self):
        print("input ",self.filename)
        print("variable ",self.varname)

        obs_line = open(self.filename, "r")
        lines = len(obs_line.readlines())
        #print(lines)

        lat=np.ndarray(shape=(lines), dtype=np.float32, order='F')
        lon=np.ndarray(shape=(lines), dtype=np.float32, order='F')
        val=np.ndarray(shape=(lines), dtype=np.float32, order='F')
        err=np.ndarray(shape=(lines), dtype=np.float32, order='F')
        qc =np.ndarray(shape=(lines), dtype=np.int32, order='F')
        if ( self.varname == 'waterTemperature' or  self.varname == 'salinity'):
           depth  =np.ndarray(shape=(lines), dtype=np.float32, order='F')
         
        dates = []

        valKey = self.varname, iconv.OvalName()
        errKey = self.varname, iconv.OerrName()
        qcKey = self.varname, iconv.OqcName()

        obs_txt = open(self.filename, "r")
        i=0
        for line in obs_txt:
            b = str(line.split()[0])
            yyyy=int(b[0:4])
            mm=int(b[4:6])
            dd=int(b[6:8])
            hh=int(b[8:10])
            mn=int(b[10:12])
            sa = datetime(yyyy, mm, dd, hh, mn, 0, 0)

            lat[i] = float(line.split()[1])
            lon[i] = float(line.split()[2])
            val[i] = float(line.split()[3])
            err[i] = float(line.split()[4])
            qc[i]  = float(line.split()[5])
            if (self.varname == 'waterTemperature' or  self.varname == 'salinity'):
               depth[i] = float(line.split()[6])

            if (self.varname == 'waterTemperature' or  self.varname == 'salinity'):
               locKey = lat[i], lon[i], depth[i], sa.strftime("%Y-%m-%dT%H:%M:%SZ")
            else:
               locKey = lat[i], lon[i], sa.strftime("%Y-%m-%dT%H:%M:%SZ")
               #print(sa.strftime("%Y-%m-%dT%H:%M:%SZ"))

            self.data[locKey][valKey] = val[i] 
            self.data[locKey][errKey] = err[i]
            self.data[locKey][qcKey] = qc[i]

            #print(i)
            i=i+1
        obs_txt.close()

def main():

    # get command line arguments
    parser = argparse.ArgumentParser(
        description=(
            'read RTOFS obs ascii file'
            'write IODA V3 netCDF file')
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-i', '--input',
        help="RTOFS obs ascii input file",
        type=str, required=True)
    required.add_argument(
        '-v', '--varname',
        help="IODA V3 variable name, e.g., sea_surface_Temperature",
        type=str, required=True)
    required.add_argument(
        '-o', '--output',
        help="IODA V3 output file",
        type=str, required=True)
    args = parser.parse_args()

    # Read in the marine data
    obs = marine(args.input,args.varname)

    # write them out
    if (args.varname == 'waterTemperature' or args.varname == 'salinity'):
       ObsVars, Location = iconv.ExtractObsData(obs.data, locationKeyListpfl)
    else:
       ObsVars, Location = iconv.ExtractObsData(obs.data, locationKeyList)

    DimDict = {'Location': Location}
    if (args.varname == 'waterTemperature' or args.varname == 'salinity'):
       writer = iconv.IodaWriter(args.output, locationKeyListpfl, DimDict)
    else:
       writer = iconv.IodaWriter(args.output, locationKeyList, DimDict)

    VarAttrs = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
    VarAttrs[(args.varname, 'ObsValue')]['_FillValue'] = 999
    VarAttrs[(args.varname, 'ObsError')]['_FillValue'] = 999
    VarAttrs[(args.varname, 'PreQC')]['_FillValue'] = 999

    writer.BuildIoda(ObsVars, VarDims, VarAttrs, GlobalAttrs)

if __name__ == '__main__':
    main()

