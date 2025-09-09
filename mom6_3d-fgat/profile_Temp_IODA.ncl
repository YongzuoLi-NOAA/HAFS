;*************************************************
;
;*************************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;----------------------------------------------------------------------
; Procedure for adding a labelbar at a given NDC location, given
; the levels and colors to use.
;----------------------------------------------------------------------
undef("add_labelbar")
procedure add_labelbar(wks,plot,levels,colors)
local lbres, labels
begin
  nlevels = dimsizes(levels)
;----------------------------------------------------------------------
; Draw a labelbar
;----------------------------------------------------------------------
  lbres                    = True
  ;lbres@lbAutoManage       = False
  lbres@vpWidthF           = 0.80             ; width
  lbres@vpHeightF          = 0.16             ; height

  lbres@lbPerimOn          = False            ; Turn off perimeter.
  lbres@lbOrientation      = "Horizontal"     ; Default is vertical.
  lbres@lbLabelAlignment   = "InteriorEdges"  ; Default is "BoxCenters"
  lbres@lbFillColors       = colors           ; Colors for boxes.
  lbres@lbMonoFillPattern  = True             ; Fill them all solid.
  lbres@lbLabelFontHeightF = 0.019            ; label font height
  ;lbres@lbLabelOffsetF     = 0.23   ; move the label closer to the plot
  ;lbres@lbBottomMarginF = 0.5

  labels = sprintf("%3.0f",levels)

  lbid = gsn_create_labelbar(wks,nlevels+1,labels,lbres)
   
  amres                  = True
  amres@amJust           = "TopCenter"
  amres@amParallelPosF   =  0.0   ; keep labelbar centered
  amres@amOrthogonalPosF =  0.6   ; move down and outside of plot

;
; Give both annotation id and labelbar id unique names.
;
; Attaching them to plot with unique names ensures that
; labelbar "lives" outside this procedure.
;
  tmpid1 = "anno"+unique_string("id")
  tmpid2 = "lbar"+unique_string("id")

  plot@$tmpid1$ = gsn_add_annotation(plot,lbid,amres)
  plot@$tmpid2$ = lbid
end

;----------------------------------------------------------------------
; Main code.
;----------------------------------------------------------------------
begin
;-------Options--------

  levels = (/5.,10.,15.,20.,25.,30.,35./) ; bin settings (bin0 = < 0., 
                                         ; bin1 = 0.:4.999, etc.)
  nlevels = dimsizes(levels)
  ;colors  = span_color_rgba("NCV_jet",nlevels+1)
  colors  = span_color_rgba("gui_default",nlevels+1)

;---------------------------
   DATES=asciiread("dates",-1,"integer")
   DTYPES=asciiread("ncfile",-1,"string")
   ;DTYPES=asciiread("ncfiles",-1,"string")
   ;DTYPES=(/"prof_T"/)
   do idate=0,dimsizes(DATES)-1
      do itype=0,dimsizes(DTYPES)-1

   filen = DATES(idate)+"."+DTYPES(itype)
   print(" "+filen)
   a = addfile(DTYPES(itype)+".nc","r")
   print(" "+DTYPES(itype)+".nc")
   ;exit()

  lon00 = a->longitude
  lat00 = a->latitude
  lon00 = a->longitude
  depth00 = a->depth

  ;VARQ="/EffectiveQC0/"+(/"waterTemperature"/)
  VART="/ObsValue/"+(/"waterTemperature"/)
  iitype=0

  val00 = a->$VART(iitype)$
  ;qc00  = a->$VARQ(itype)$
  ;tmp00 = (ind(qc00.eq.0))

  lat = lat00
  lon = lon00
  depth = depth00
  R   = val00

  npts= dimsizes(R)
  print("lat = "+lat(0:1))
  print("lon = "+lon(0:1))
  print("prof_T = "+R(0:1))
  print("npts = "+npts)
  
  ;data  = new(npts, "string")
  i = 0
  do while(i.le.npts-1)
     if(lat(i).gt.12.0.and.lat(i).lt.16.0.and.lon(i).gt.-71.0.and.\
        lon(i).lt.-68.0) then
     ;if(lat(i).gt.20.0.and.lat(i).lt.28.0.and.\
     ;   lon(i).gt.-99.0.and.lon(i).lt.-92.0) then
     ;data(i)=(sprintf("%6.2f",lat(i))+" "+sprintf("%7.2f",lon(i))+" "+\
     ;         sprintf("%6.1f",depth(i))+" "+sprintf("%4.1f",R(i)))
     ;print(sprintf("%6.2f",lat(i))+" "+sprintf("%7.2f",lon(i))+" "+\
     ;         sprintf("%6.1f",depth(i))+" "+sprintf("%4.1f",R(i)))
     end if
     i=i+1
   end do
   ;asciiwrite("swt.txt",data)
;------------------------------ 
; Create X and Y arrays to hold the points for each range and initialize
; them to missing values.  We want to use num_distinct_markers
; different colors, so we need num_distinct_markers sets of X and
; Y points.
;
  num_distinct_markers = nlevels+1        ; number of distinct markers
  lat_new = new((/num_distinct_markers,npts/),float,-999)
  lon_new = new((/num_distinct_markers,npts/),float,-999)
;
; Group the points according to which range they fall in. At the
; same time, create the label that we will use later in the labelbar
;       
  do i = 0, num_distinct_markers-1
    if (i.eq.0) then
      indexes = ind(R.lt.levels(0))
    end if
    if (i.eq.num_distinct_markers-1) then
      indexes = ind(R.ge.max(levels))
    end if
    if (i.gt.0.and.i.lt.num_distinct_markers-1) then       
      indexes = ind(R.ge.levels(i-1).and.R.lt.levels(i))
    end if
;
; Now that we have the set of indexes whose values fall within 
; the given range, take the corresponding lat/lon values and store
; them, so later we can color this set of markers with the appropriate
; color.
;
    if (.not.any(ismissing(indexes))) then 
      npts_range = dimsizes(indexes)   ; # of points in this range.
      lat_new(i,0:npts_range-1) = lat(indexes)
      lon_new(i,0:npts_range-1) = lon(indexes)
    end if
    delete(indexes)            ; Necessary b/c "indexes" may be a different
                               ; size next time.
  end do

;===========================================================================
; Begin plotting section.
;
  wks = gsn_open_wks("png",filen)              ; send graphics to PNG file

;---Set up some map resources.
  mpres                       = True
  mpres@gsnMaximize           = True             ; Maximize plot in frame.
  mpres@gsnDraw               = False            ; Will draw later
  mpres@gsnFrame              = False            ; Don't advance the frame
  mpres@pmTickMarkDisplayMode = "Always"

   mpres@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
   mpres@mpNationalLineColor         = "Black"
   mpres@mpUSStateLineColor          = "Black"
   mpres@mpLimbLineColor             = "Black"
   mpres@mpPerimLineColor            = "Black"
   mpres@mpGridSpacingF              = 5.
   mpres@mpGridLatSpacingF           = 5.
   mpres@mpGridLonSpacingF           = 5.
   mpres@mpGridLineColor             = "Black"
   mpres@mpGeophysicalLineColor      = "Black"
   mpres@mpGeophysicalLineThicknessF = 2.0
   mpres@mpGridLineThicknessF        = 2.0
   mpres@mpLimbLineThicknessF        = 2.0
   mpres@mpNationalLineThicknessF    = 2.0
   mpres@mpUSStateLineThicknessF     = 2.0
   mpres@mpFillOn                = False
   ;mpres@mpFillDrawOrder        = "PostDraw"     ; draw map fill last
   mpres@pmTickMarkDisplayMode   = "Always"
   mpres@tmXBMajorLineColor      = "Green"
   mpres@tmYLMajorLineColor      = "Red"
   mpres@tmXBMajorLengthF        = 0.01
   mpres@tmYLMajorLengthF        = 0.01
   mpres@tmXBMajorOutwardLengthF = 0.
   mpres@tmYLMajorOutwardLengthF = 0.
   mpres@tmXTOn                  = True
   mpres@tmYROn                  = True
   mpres@tmYLMinorOn             = False
   mpres@tmXBMinorOn             = False
;---Zoom in on United States.

  mpres@tiMainString          = filen
  map = gsn_csm_map(wks,mpres)

;--Create logical variables to hold the marker resources.
  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
;
; Loop through each grouping of markers, and draw them one set at
; a time, assigning the proper color and size with gsn_marker.
;
  base_size = 0.004
  pmid = new(num_distinct_markers,graphic)
  do i = 0, num_distinct_markers-1
    if (.not.ismissing(lat_new(i,0)))
      gsres@gsMarkerColor      = colors(i,:)
      gsres@gsMarkerSizeF      = base_size  ; * (i+1)/3.
      gsres@gsMarkerThicknessF = 0.7*(i+1)
      pmid(i) = gsn_add_polymarker(wks,map,lon_new(i,:),lat_new(i,:),gsres)
    end if
  end do

;---Draw labelbar and advance frame.
  add_labelbar(wks,map,levels,colors)
  draw(map)
  frame(wks)
  system("convert -trim "+filen+".png "+filen+".png")
  delete([/depth,depth00,val00,lat00,lon00,lat,lon,R,lat_new,lon_new/])

 end do
 end do
end     


