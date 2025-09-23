#!/usr/bin/env python3
import numpy as np
from netCDF4 import Dataset
# top of file
from decimal import Decimal, ROUND_HALF_UP

# --- inputs ---
INFILE = "prof_T_2023120912.nc"
LAYERZ_FILE = "layerz_wx.txt"    # your MOM6 layer edges (75 numbers)
# variables to carry along
META_VARS = ["depth", "latitude", "longitude", "dateTime"]
OBS_VARS  = ["waterTemperature"]   # add "salinity" etc if needed
# ----------------

# replace your copy_attrs with:
def copy_attrs(src_obj, dst_obj, skip=()):
    for a in src_obj.ncattrs():
        if a in skip:
            continue
        setattr(dst_obj, a, getattr(src_obj, a))

#def copy_attrs(src_obj, dst_obj):
#    for a in src_obj.ncattrs():
#        setattr(dst_obj, a, getattr(src_obj, a))

def subset_and_write(idx, upper_edge_str, src):
    if idx.size == 0:
        return 0
    # in subset_and_write(), replace the line that builds outname:
    #outname = f"T_layer_{upper_edge_str}m.nc"
    #outname = f"T_layer_{upper_edge_str}m.nc"
    outname = f"T_layer_{depth_tag(upper_edge_str)}m.nc"

    with Dataset(outname, "w", format="NETCDF4") as dst:
        # global attrs
        copy_attrs(src, dst)

        # Location dim & var
        nrec = idx.size
        dst.createDimension("Location", nrec)
        if "Location" in src.variables:
            loc_src = src.variables["Location"]
            fill = getattr(loc_src, "_FillValue", None)

# Location
            loc_dst = dst.createVariable("Location", loc_src.dtype, ("Location",),
                             zlib=True, fill_value=fill)
            copy_attrs(loc_src, loc_dst, skip=('_FillValue',))  # <-- skip FillValue
            loc_dst[:] = loc_src[idx]

            #loc_dst = dst.createVariable("Location", loc_src.dtype, ("Location",),
            #                             zlib=True, fill_value=fill)
            #copy_attrs(loc_src, loc_dst)
            #loc_dst[:] = loc_src[idx]
        else:
            # create a simple 0..n-1 index if not present
            loc_dst = dst.createVariable("Location", "i8", ("Location",), zlib=True)
            loc_dst[:] = np.arange(nrec, dtype=np.int64)

        # groups: MetaData, ObsValue (and copy attrs)

        for gname, varlist in [("MetaData", META_VARS), ("ObsValue", OBS_VARS)]:
            gsrc = src.groups[gname]
            gdst = dst.createGroup(gname)
            copy_attrs(gsrc, gdst)

            for vname in varlist:
                vsrc = gsrc.variables[vname]
                fill = getattr(vsrc, "_FillValue", None)
                vdst = gdst.createVariable(vname, vsrc.dtype, ("Location",),
                                           zlib=True, fill_value=fill)
                copy_attrs(vsrc, vdst, skip=('_FillValue',))  # <-- skip FillValue
                vdst[:] = vsrc[idx]
                #copy_attrs(src, dst)          # globals ok
                #copy_attrs(gsrc, gdst)        # group attrs ok

            #for vname in varlist:
            #    vsrc = gsrc.variables[vname]
            #    fill = getattr(vsrc, "_FillValue", None)
            #    vdst = gdst.createVariable(vname, vsrc.dtype, ("Location",),
            #                               zlib=True, fill_value=fill)
            #    copy_attrs(vsrc, vdst)
            #    vdst[:] = vsrc[idx]
    return nrec

# add helper (anywhere above main())
def depth_tag(h: float) -> str:
    """
    Round to nearest integer meter using HALF_UP
    and return zero-padded 4-digit string.
    """
    rounded = int(Decimal(str(h)).quantize(Decimal('1'), rounding=ROUND_HALF_UP))
    return f"{rounded:04d}"

def main():
    # load layer edges (assumed one line list or whitespace-separated)
    # load layer edges as a flat, 1-D increasing array
    edges = np.loadtxt(LAYERZ_FILE, dtype=float).ravel()   # <— flatten 15x5 -> 75
    # sanity checks (optional but helpful)
    if edges.ndim != 1:
        edges = edges.reshape(-1)
    if np.any(np.diff(edges) <= 0):
        raise ValueError("Layer edges must be strictly increasing")
    print("edges count:", edges.size, "min/max:", edges.min(), edges.max())
    #edges = np.loadtxt(LAYERZ_FILE, dtype=float)
    # build [edge_i, edge_{i+1}) bins
    lo = edges[:-1]
    hi = edges[1:]

    with Dataset(INFILE, "r") as src:
        depth = src.groups["MetaData"].variables["depth"][:]
        for l, h in zip(lo, hi):
            mask = (depth >= l) & (depth < h)
            idx = np.where(mask)[0]
            n = subset_and_write(idx, f"{h:.3f}".rstrip('0').rstrip('.'), src)
            print(f"[{l:.3f}, {h:.3f}) -> {n} records")

if __name__ == "__main__":
    main()


