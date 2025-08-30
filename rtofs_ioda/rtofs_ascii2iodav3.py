#!/usr/bin/env python3
# rtofs_ascii2iodav3.py

import argparse
import datetime as dt
import numpy as np
from warnings import filterwarnings
filterwarnings(action='ignore', category=DeprecationWarning, message='`np.bool` is a deprecated alias')

import pyiodaconv.ioda_conv_engines as iconv
from pyiodaconv.orddicts import DefaultOrderedDict

# -----------------------------
# IODA config
# -----------------------------
vName = ["waterTemperature", "salinity"]

# Use long epoch seconds for dateTime
locationKeyList = [
    ("latitude", "float"),
    ("longitude", "float"),
    ("dateTime", "long"),
]

locationKeyListpfl = [
    ("latitude", "float"),
    ("longitude", "float"),
    ("depthBelowWaterSurface", "float"),
    ("dateTime", "long"),
]

GlobalAttrs = {"odb_version": 1}
DimDict = {}
VarDims = {" ": ["nlocs"]}

# -----------------------------
# Reader / Converter
# -----------------------------
class Marine:
    def __init__(self, filename: str, varname: str):
        self.filename = filename
        self.varname = varname

        self.varDict = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.metaDict = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.data = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.var_mdata = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))
        self.VarAttrs = DefaultOrderedDict(lambda: DefaultOrderedDict(dict))

        self.floatDefFillVal = iconv.get_default_fill_val("float32")
        self.intDefFillVal = iconv.get_default_fill_val("int32")

        # Standard attributes for Obs groups
        self.VarAttrs[(self.varname, iconv.OvalName())]["_FillValue"] = self.floatDefFillVal
        self.VarAttrs[(self.varname, iconv.OerrName())]["_FillValue"] = self.floatDefFillVal
        self.VarAttrs[(self.varname, iconv.OqcName())]["_FillValue"] = self.intDefFillVal

        # MetaData attributes (units, etc.)
        self.VarAttrs[("latitude", "MetaData")]["units"] = "degrees_north"
        self.VarAttrs[("longitude", "MetaData")]["units"] = "degrees_east"
        self.VarAttrs[("depthBelowWaterSurface", "MetaData")]["units"] = "m"
        self.VarAttrs[("dateTime", "MetaData")]["units"] = "seconds since 1970-01-01T00:00:00Z"
        self.VarAttrs[("dateTime", "MetaData")]["calendar"] = "gregorian"
        self.VarAttrs[("dateTime", "MetaData")]["_FillValue"] = np.int64(-9223372036854775806)

        self._read()

    @staticmethod
    def _parse_epoch_yyyymmddhhmn(s: str) -> int:
        # e.g., "202406250013" -> epoch seconds (UTC)
        dt_naive = dt.datetime.strptime(s, "%Y%m%d%H%M")
        return int(dt_naive.replace(tzinfo=dt.timezone.utc).timestamp())

    def _read(self):
        """
        Expected ASCII columns (as in your sample):
        time(YYYYMMDDHHMN)  lat  lon  main_val  main_err  main_qc  aux_val  aux_err  aux_qc  depth
        For waterTemperature mode, 'main_*' map to waterTemperature and 'aux_*' to salinity.
        For salinity mode, they’re still read but the focus is salinity; both values are saved if present.
        """
        want_aux = (self.varname == "waterTemperature") or (self.varname == "salinity")
        valKey   = (self.varname, iconv.OvalName())
        errKey   = (self.varname, iconv.OerrName())
        qcKey    = (self.varname, iconv.OqcName())

        # If we have both temperature and salinity in the file, store both ObsValue/ObsError/PreQC
        if want_aux:
            aux_name = "salinity" if self.varname in ("waterTemperature", "salinity") else None
            if aux_name:
                sws_valKey = (aux_name, iconv.OvalName())
                sws_errKey = (aux_name, iconv.OerrName())
                sws_qcKey  = (aux_name, iconv.OqcName())
                # Fill values
                self.VarAttrs[(aux_name, iconv.OvalName())]["_FillValue"] = self.floatDefFillVal
                self.VarAttrs[(aux_name, iconv.OerrName())]["_FillValue"] = self.floatDefFillVal
                self.VarAttrs[(aux_name, iconv.OqcName())]["_FillValue"]  = self.intDefFillVal

        with open(self.filename, "r") as f:
            for line in f:
                if not line.strip():
                    continue
                parts = line.split()
                # Guard against short lines
                if len(parts) < 6:
                    continue

                tstr = parts[0]
                lat = float(parts[1])
                lon = float(parts[2])

                main_val = float(parts[3])
                main_err = float(parts[4])
                main_qc  = float(parts[5])   # your file shows floats here; leaving as-is

                aux_val = aux_err = aux_qc = None
                depth = None

                # Optional aux + depth columns if present (as in your sample)
                if len(parts) >= 10:
                    aux_val = float(parts[6])
                    aux_err = float(parts[7])
                    aux_qc  = float(parts[8])  # also float in your sample
                    depth   = float(parts[9])

                epoch = self._parse_epoch_yyyymmddhhmn(tstr)

                if depth is not None:
                    locKey = (lat, lon, depth, np.int64(epoch))
                else:
                    locKey = (lat, lon, np.int64(epoch))

                # Main variable
                self.data[locKey][valKey] = main_val
                self.data[locKey][errKey] = main_err
                self.data[locKey][qcKey]  = main_qc

                # Aux variable (e.g., salinity) if present
                if want_aux and (aux_val is not None):
                    self.data[locKey][sws_valKey] = aux_val
                    self.data[locKey][sws_errKey] = aux_err
                    self.data[locKey][sws_qcKey]  = aux_qc


def main():
    parser = argparse.ArgumentParser(
        description="Read RTOFS ASCII profile and write IODA v3 netCDF."
    )
    req = parser.add_argument_group(title="required")
    req.add_argument("-i", "--input",  type=str, required=True, help="ASCII input file")
    req.add_argument("-v", "--varname", type=str, required=True, choices=vName,
                     help="IODA V3 variable name: waterTemperature or salinity")
    req.add_argument("-o", "--output", type=str, required=True, help="IODA v3 output .nc")

    args = parser.parse_args()

    obs = Marine(args.input, args.varname)

    # Choose location key list depending on presence of depth in the data.
    # Heuristic: if any locKey is 4-tuple, we used depth and should pick the profile list.
    used_depth = any((len(k) == 4) for k in obs.data.keys())

    if used_depth:
        ObsVars, Location = iconv.ExtractObsData(obs.data, locationKeyListpfl)
        writer = iconv.IodaWriter(args.output, locationKeyListpfl, {"Location": Location})
    else:
        ObsVars, Location = iconv.ExtractObsData(obs.data, locationKeyList)
        writer = iconv.IodaWriter(args.output, locationKeyList, {"Location": Location})

    # You can also add units for ObsValue variables if desired (optional)
    # e.g., writer-side VarAttrs for waterTemperature/salinity:
    # obs.VarAttrs[("waterTemperature", iconv.OvalName())]["units"] = "degC"
    # obs.VarAttrs[("salinity", iconv.OvalName())]["units"] = "1e-3"  # practical salinity (PSU ~ unitless)

    writer.BuildIoda(ObsVars, VarDims, obs.VarAttrs, GlobalAttrs)


if __name__ == "__main__":
    main()

