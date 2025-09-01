err = NhlGetErrorObjectId()
setvalues err
 "errLevel" : "Fatal"          ; only report Fatal errors
end setvalues
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setvalues NhlGetWorkspaceObjectId()
 "wsMaximumSize" : 300000000
end setvalues
;*************************************************
; WRF: simple wind vectors and wind barbs
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
begin
;************************************************
; open file and read U and V data
;************************************************
 type   = "png"
 itime=ispan(0,0,3)
 tt=sprinti("%0.3i",itime)

 DATES=asciiread("dates",-1,"integer")
 DTYPES=(/"Temp"/)

 do idate=0,dimsizes(DATES)-1
  do itype=0,dimsizes(DTYPES)-1
   do k=0,60

    a = addfile("diff_Temp.nc","r")

    lat1d = a->lath
    lon1d = a->lonh
    layer = a->Layer(k)

    if(k.le.4) then
    filen="incr_"+DTYPES(itype)+"_"+DATES(idate)+"_L000"+doubletoint(layer)+"m"
    end if

    if(k.ge.5.and.k.le.29) then
    filen="incr_"+DTYPES(itype)+"_"+DATES(idate)+"_L00"+doubletoint(layer)+"m"
    end if

    if(k.ge.30.and.k.le.49) then
    filen="incr_"+DTYPES(itype)+"_"+DATES(idate)+"_L0"+doubletoint(layer)+"m"
    end if

    if(k.ge.50.and.k.le.60) then
    filen="incr_"+DTYPES(itype)+"_"+DATES(idate)+"_L"+doubletoint(layer)+"m"
    end if

    wks = gsn_open_wks(type ,filen)

    colors = (/"White","Black","Blue","NavyBlue","LightSkyBlue","Green","PaleGreen",\
             "White","yellow","DarkOrange","tomato","red"/)
    gsn_define_colormap(wks, colors) 

    lon=new((/dimsizes(lat1d),dimsizes(lon1d)/),typeof(lat1d))
    lat=lon
    do i=0,dimsizes(lat1d)-1
     lon(i,:)=lon1d
    end do
    do i=0,dimsizes(lon1d)-1
     lat(:,i)=lat1d
    end do

    temp = a->Temp(0,k,:,:)
    temp@_FillValue = 1e+20
    temp@missing_value = 1e+20
    temp=where(temp.eq.0,temp@_FillValue,temp)

    print(sprintf("%4.0f", k)+" "+sprintf("%7.2f", layer)+"m "+sprintf("%5.2f", max(temp))+" "+sprintf("%5.2f",min(temp)))
   temp@lat2d = lat
   temp@lon2d = lon
   temp@long_name = "Temp increment"
   temp@units = "K"

   res             = True             ; plot mods desired
   res@gsnDraw     = False                         ; don't draw
   res@gsnFrame    = False
   res@mpDataBaseVersion = "MediumRes"
   res@mpProjection      = "CylindricalEquidistant"
   res@mpLimitMode       = "Latlon"
   res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
   res@mpNationalLineColor         = "Black"
   res@mpUSStateLineColor          = "Black"
   res@mpLimbLineColor             = "Black"
   res@mpPerimLineColor            = "Black"
   res@mpGridSpacingF              = 5.
   res@mpGridLatSpacingF           = 5.
   res@mpGridLonSpacingF           = 5.
   res@mpGridLineColor             = "Black"
   res@mpGeophysicalLineColor      = "Black"
   res@mpGeophysicalLineThicknessF = 2.0
   res@mpGridLineThicknessF        = 2.0
   res@mpLimbLineThicknessF        = 2.0
   res@mpNationalLineThicknessF    = 2.0
   res@mpUSStateLineThicknessF     = 2.0
   res@mpFillOn = False
   res@pmTickMarkDisplayMode   = "Always"
   res@tmXBMajorLineColor      = "Green"
   res@tmYLMajorLineColor      = "Red"
   res@tmXBMajorLengthF        = 0.01
   res@tmYLMajorLengthF        = 0.01
   res@tmXBMajorOutwardLengthF = 0.
   res@tmYLMajorOutwardLengthF = 0.
   res@tmXTOn                  = False
   res@tmYROn                  = False
   res@tmYLMinorOn             = False
   res@tmXBMinorOn             = False
 
   res@gsnScalarContour        = True

   res@cnLevelSelectionMode = "ExplicitLevels"
   res@cnFillColors = (/"Blue","LightSkyBlue","PaleGreen","Green",\
             "White","White","yellow","DarkOrange","tomato","red"/)

   res@cnFillOn            = True              ; turn on color fill
   res@cnLinesOn           = True              ; turn off contour lines
   res@cnLevels            = (/-0.9,-0.6,-0.3,-0.1,0,0.1,0.3,0.6,0.9/)

   res@lbTitlePosition  = "Bottom"
   res@lbTitleFontHeightF= .018
   res@lbTitleDirection = "Across" 
   res@gsnMaximize             = True
   res@tiMainString            = filen
   res@tiMainOffsetYF = -0.044
   plot = gsn_csm_contour_map(wks,temp,res)
   draw(plot)
   frame(wks)
   system("convert -trim "+filen+".png "+filen+".png")
   delete([/temp/])
   end do
  end do
 end do
end
