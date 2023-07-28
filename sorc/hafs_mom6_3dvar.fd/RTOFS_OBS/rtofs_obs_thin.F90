      program rtofs_obs_thin

!     This program calls 3 subroutines: read_sst, read_ssh, and
!     read_profile

      character argv*12

      call getarg(1, argv)

      if(argv.eq.'thin_sst') then
         print*, 'thin_sst'
         call thin_sst
      endif

      if(argv.eq.'read_ssh') then
         print*, 'read_ssh'
         call read_ssh
      endif

      if(argv.eq.'read_profile') then
         print*, 'read_profile'
         call read_profile
      endif

      if(argv.eq.'read_sss') then
         print*, 'read_sss'
         call read_sss
      endif

      stop
      end 

!       ###### read RTOFS SST binary ######

      subroutine thin_sst()

      parameter(kk=100,jj=565,ii=1135)  
      !parameter(kk=200,jj=225,ii=450)  
       
      character ob_dtg *12, dtg(jj,ii) *12
      REAL ob_lat,ob_lon,ob_sst,ob_err,ob_qc

      integer bk(jj,ii)
      real lat(jj,ii),lon(jj,ii),sst(jj,ii),err(jj,ii),qc(jj,ii)

      real latk(kk,jj,ii),lonk(kk,jj,ii),sstk(kk,jj,ii),
     6     errk(kk,jj,ii),qck(kk,jj,ii)

!     hat10 south lat, west lon
      lats = 1
      lonw = -98
      ds   = 0.08
      !ds   = 0.2

      do j = 1, jj
      do i = 1, ii
        lat(j,i) = 0
        lon(j,i) = 0
        sst(j,i) = 0
        err(j,i) = 0
        qc(j,i) = 0
        bk(j,i) = 0
      enddo
      enddo

        open(10,file='sst.txt',status='old')
        open(20,file='sst.thin',status='unknown')

99    continue
      read(10,25,end=88) ob_dtg,ob_lat,ob_lon,ob_sst,ob_err,ob_qc
      if(ob_err.lt.0.05) write(*,*) 'SMALL OBS ERROR.....',ob_err

      jy = int((ob_lat-lats)/ds)+1
      ix = int((ob_lon-lonw)/ds)+1

!     hat10
      if(ix.ge.1.and.ix.le.ii.and.jy.ge.1.and.jy.le.jj) then
      !if(jy.eq.213.and.ix.eq.144) then

!     time string
      dtg(jy,ix)=ob_dtg

!     for box average
      lat(jy,ix)=lat(jy,ix) + ob_lat
      lon(jy,ix)=lon(jy,ix) + ob_lon
      sst(jy,ix)=sst(jy,ix) + ob_sst
      err(jy,ix)=err(jy,ix) + ob_err
       qc(jy,ix)= qc(jy,ix) + ob_qc
       bk(jy,ix)= bk(jy,ix) + 1

!     individual in a box
      k=bk(jy,ix)
      latk(k,jy,ix)=ob_lat
      lonk(k,jy,ix)=ob_lon
      sstk(k,jy,ix)=ob_sst
      errk(k,jy,ix)=ob_err
       qck(k,jy,ix)=ob_qc

      !if(jy.eq.213.and.ix.eq.144) then
      !write(*,*) k,sstk(k,jy,ix)
      !endif

      endif  ! hat10

      goto 99  ! All stations

88    continue
      write(*,*) 'finishing reading'

      !write(*,*) 'kk',(sstk(k,213,144),k=1,bk(213,144))
      !stop

!     Average
      errmin=10.0
      errmax=0.0
      do j = 1, jj
      do i = 1, ii

      if(bk(j,i).ge.1) then
      lat(j,i)=lat(j,i)/bk(j,i)
      lon(j,i)=lon(j,i)/bk(j,i)
      sst(j,i)=sst(j,i)/bk(j,i)
      err(j,i)=err(j,i)/bk(j,i)
      qc(j,i)=qc(j,i)/bk(j,i)

      if(err(j,i).gt.errmax) errmax=err(j,i)
      if(err(j,i).lt.errmin) errmin=err(j,i)

      endif

      enddo
      enddo

      write(*,*)'errmax errmin ...',errmax,errmin

      write(*,*) 'buddy average check ..........'
      isobs = 0
      nnn=0

      do j = 2, jj-1
      do i = 2, ii-1

      if(bk(j,i).eq.1) then
      bk(j,i)=0
      isobs=isobs+1
      endif

      if(bk(j,i).gt.1) then
      nn=bk(j,i)

      mmm=0
77    continue
      do n=1,nn

      ti=sstk(n,j,i)
      ta=sst(j,i)

      if(abs(ti-ta).gt.2.5) then

      nnn=nnn+1
      mmm=mmm+1
      write(*,*) '+++++++++++++++ This 0.08X0.08 deg Box +++++++++'

      write(*,'(2(a5,f7.2))') 'lat= ',lat(j,i),' lon= ',lon(j,i)
      write(*,'(3(a14,i3))') 'total outlier=',mmm,' outlier ID ', n,
     6           'total SST',nn
      write(*,*) ' outlier sst ...',ti,'this mean...',ta
      write(*,*) 'SST ',(sstk(m,j,i),m=1,nn) 
      sstk(n,j,i)=ta

      tv=0
      do m=1,nn
      tv=tv+sstk(m,j,i)
      enddo
      sst(j,i)=tv/bk(j,i)
      write(*,*) 'new mean....',sst(j,i)
      goto 77

      endif  ! diff ti - ta

      enddo  ! n loop

      endif  ! bk > 1

      enddo
      enddo

      write(*,*) 'isobs = ....      ', isobs
      write(*,*) 'buddy check = ....', nnn

!     write for ioda
      do j = 1, jj
      do i = 1, ii

      if(bk(j,i).ge.1.0) then
      write(20,25) dtg(j,i),lat(j,i),lon(j,i),sst(j,i),err(j,i),
     6             qc(j,i)
      endif

      enddo
      enddo

25    format(a12,1x,f6.3,1x,f8.3,3(1x,f6.3))
      close(10)

      return
      end

!     ###### read RTOFS SSH binary ######

      subroutine read_ssh()
        
      integer   n_lvl
      integer   n_read
      integer   vrsn

      real,     allocatable :: ob_age (:)
      integer,  allocatable :: ob_cyc (:)
      character,allocatable :: ob_dtg (:) * 14
      real,     allocatable :: ob_lat (:)
      real,     allocatable :: ob_lon (:)
      real,     allocatable :: ob_qc (:)
      integer,  allocatable :: ob_ltc (:)
      character,allocatable :: ob_rcpt (:) * 14
      integer,  allocatable :: ob_sat (:)
      integer,  allocatable :: ob_smpl (:)
      real,     allocatable :: ob_ssh (:)
      integer,  allocatable :: ob_trck (:) 
        
      character winstart *12, winend *12

      open(10,file='ssh.bin',form='unformatted')

      write(*,*) 'reading SST'

      read (10) n_read, n_lvl, vrsn

      if (n_read .gt. 0) then

      allocate (ob_age(n_read))
      allocate (ob_cyc(n_read))
      allocate (ob_lat(n_read))
      allocate (ob_lon(n_read))
      allocate (ob_qc(n_read))
      allocate (ob_sat(n_read))
      allocate (ob_smpl(n_read))
      allocate (ob_ssh(n_read))
      allocate (ob_trck(n_read))
      allocate (ob_ltc(n_read))
      allocate (ob_dtg(n_read))
      allocate (ob_rcpt(n_read))

      read (10) ob_age(1:n_read)
      read (10) ob_cyc(1:n_read)
      read (10) ob_lat(1:n_read)
      read (10) ob_lon(1:n_read)
      read (10) ob_qc(1:n_read)
      read (10) ob_sat(1:n_read)
      read (10) ob_smpl(1:n_read)
      read (10) ob_ssh(1:n_read)
      read (10) ob_trck(1:n_read)
      read (10) ob_ltc(1:n_read)
      read (10) ob_dtg(1:n_read)
      read (10) ob_rcpt(1:n_read)

      open(21,file='window.txt',status='old')
      read(21,'(a12)') winstart
      read(21,'(a12)') winend
      close(21)

      open(20,file='ssh.txt',status='unknown')
        
      do i=1, n_read

!     HAT10
      if(ob_lat(i).ge.1.0.and.ob_lat(i).le.50.0.and.
     6   ob_lon(i).ge.-100.0.and.ob_lon(i).le.-7.0) then

!     time window
      if(ob_dtg(i)(1:12).ge.winstart.and.ob_dtg(i)(1:12).le.
     6   winend) then

      if(ob_dtg(i)(13:14).gt."59") ob_dtg(i)(13:14)="59"
      if(ob_dtg(i)(11:12).gt."59") ob_dtg(i)(11:12)="59"

      write(20,25) ob_dtg(i)(1:12),ob_lat(i),ob_lon(i),
     6             ob_ssh(i),0.1,ob_qc(i)

      endif ! End of time window
      endif ! End of HAT10

      enddo

25    format(a12,1x,f6.3,1x,f8.3,3(1x,f6.3))
      close(20)

      endif

      return
      end

!     ###### read RTOFS PROFILE binary ######

      subroutine read_profile()
c     implicit none
c
c     ..define maximum number daily files
c
      integer    MX_FILES
      parameter (MX_FILES = 300)
c
      integer    UNIT
      parameter (UNIT = 20)
c
      integer   n_depth
      integer   n_prf
      parameter(n_depth=2500, n_prf=7500)
c
      character winstart *12, winend *12
      logical   exist
      character file_dtg (MX_FILES) * 10
      character file_name * 256
      integer   i, j
      integer   len
      integer   len_data
      integer   mx_depth
      integer   mx_obs
      integer   n_dup
      integer   n_files
      integer   n_in
      integer   n_lev
      integer   n_out
      integer   n_rpl
      logical   new_file
      integer   old_vrsn
      real      qc_lmt
      integer   total
      integer   vrsn

      real      clm_sal (n_depth, n_prf)
      real      clm_sstd (n_depth, n_prf)
      real      clm_tmp (n_depth, n_prf)
      real      clm_tstd (n_depth, n_prf)
      logical   dup_prf (n_prf)
      real      prf_btm (n_prf)
c     character prf_dtg (n_prf) * 12
      integer   ob_flg (n_depth, n_prf)
c     real      prf_lat (n_prf)
      real      prf_lon (n_prf)
      integer   prf_ls (n_prf)
c      integer   prf_lt (n_prf)
      integer,  allocatable :: prf_lt (:)
c     real      prf_lvl (n_depth, n_prf)
      character,allocatable :: prf_dtg (:) * 12
      real,     allocatable :: prf_lat (:)
      real,     allocatable :: prf_lvl (:,:)
      character prf_rcpt (n_prf) * 12
      integer   prf_rej (n_depth, n_prf)
      real      prf_sal (n_depth, n_prf)
      real      prf_sal_err (n_depth, n_prf)
      integer   prf_sal_typ (n_prf)
      character prf_sgn (n_prf) * 7
      real      prf_sprb (n_depth, n_prf)

      character prf_csal (n_depth, n_prf) * 7
      real      prf_cssd (n_depth, n_prf)
      character prf_ctmp (n_depth, n_prf) * 7
      real      prf_ctsd (n_depth, n_prf)

      real      prf_sqc (n_prf)
      real      prf_tmp (n_depth, n_prf)
      real      prf_tmp_err (n_depth, n_prf)
      integer   prf_tmp_typ (n_prf)
      real      prf_tprb (n_depth, n_prf)
      real      prf_tqc (n_prf)
      real      prf_rct (n_prf)

      open (UNIT, file='profile.bin', status='old',
     6      form='unformatted')

      read (UNIT) n_in, n_lev, old_vrsn
      write(*,*) ' n_in, n_lev, old_vrsn',  n_in, n_lev, old_vrsn

      if (n_in .gt. 0) then
      allocate (prf_lat (n_in))
      allocate (prf_dtg (n_in))
      allocate (prf_lt (n_in))
      allocate (prf_lvl (n_lev, n_in))

      read (unit) prf_btm(1:n_in)
      read (unit) prf_lat(1:n_in)
      read (unit) prf_lon(1:n_in)
      read (unit) prf_ls(1:n_in)
      read (unit) prf_lt(1:n_in)
      read (unit) prf_sal_typ(1:n_in)
      read (unit) prf_sqc(1:n_in)
      read (unit) prf_tmp_typ(1:n_in)
      read (unit) prf_tqc(1:n_in)

      do i = 1, n_in
         read (unit) prf_lvl(1:prf_lt(i),i)
         read (unit) prf_sal(1:prf_lt(i),i)
         read (unit) prf_sal_err(1:prf_lt(i),i)
         read (unit) prf_sprb(1:prf_lt(i),i)
         read (unit) prf_tmp(1:prf_lt(i),i)
         read (unit) prf_tmp_err(1:prf_lt(i),i)
         read (unit) prf_tprb(1:prf_lt(i),i)
         read (UNIT) ob_clm_sal
         read (unit) prf_cssd(1:prf_lt(i),i)
         read (UNIT) ob_clm_tmp
         read (unit) prf_ctsd(1:prf_lt(i),i)
         read (unit) ob_flg(1:prf_lt(i),i)
      enddo

      read (unit) prf_dtg(1:n_in)
      read (unit) prf_rct(1:n_in)
      read (unit) prf_sgn(1:n_in)

      close (unit)

      endif

      open(21,file='window.txt',status='old')
      read(21,'(a12)') winstart
      read(21,'(a12)') winend
      close(21)

      open(20,file='profile.txt',status='unknown')

      do i=1, n_in

!     HAT10
      if(prf_lat(i).ge.1.0.and.prf_lat(i).le.50.0.and.
     6   prf_lon(i).ge.-100.0.and.prf_lon(i).le.-7.0) then

!     time window
      if(prf_dtg(i).ge.winstart.and.prf_dtg(i).le.winend) then

      if(prf_tqc(i).gt.99.0) then
         prf_tqc(i)=99.9
      endif

      if(prf_sqc(i).gt.99.0) then
         prf_sqc(i)=99.9
      endif

!     profile
      do j=1, prf_lt(i)

      if(prf_sal_err(j,i).eq.-999.0) then
      prf_sal_err(j,i)=1.0
      endif

      if(prf_sal(j,i).gt.10.0.and.prf_sal(j,i).lt.40.0) then
      write(20,25) prf_dtg(i),prf_lat(i),prf_lon(i),
     6             prf_tmp(j,i),prf_tmp_err(j,i),prf_tqc(i),
     6             prf_sal(j,i),prf_sal_err(j,i),prf_sqc(i),
     6             prf_lvl(j,i)
      endif

      enddo ! profile

      endif ! time window

      endif ! HAT10

      enddo

25    format(a12,1x,f6.3,1x,f8.3,6(1x,f6.3),1x,f6.1)
      close(20)

      return
      end

!     ###### read RTOFS SSS binary ######

      subroutine read_sss()

      real,     allocatable :: ob_age (:)
      character,allocatable :: ob_dtg (:) * 12
      real,     allocatable :: ob_err (:)
      integer,  allocatable :: ob_flg (:)
      real,     allocatable :: ob_lat (:)
      real,     allocatable :: ob_lon (:)
      real,     allocatable :: ob_qc (:)
      character,allocatable :: ob_rcp (:) * 12
      real,     allocatable :: ob_sss (:)
      real,     allocatable :: ob_sst (:)
      integer,  allocatable :: ob_typ (:)
c
      character winstart *12, winend *12
      integer n_read, n_lvl, vrsn, i
c
      open(10,file='sss.bin',form='unformatted')

      write(*,*) 'reading RTOFS binary SSS'

      read (10) n_read, n_lvl, vrsn
      if (n_read .gt. 0) then
c
      allocate (ob_age (n_read))
      allocate (ob_dtg (n_read))
      allocate (ob_err (n_read))
      allocate (ob_flg (n_read))
      allocate (ob_lat (n_read))
      allocate (ob_lon (n_read))
      allocate (ob_qc (n_read))
      allocate (ob_rcp (n_read))
      allocate (ob_sss (n_read))
      allocate (ob_sst (n_read))
      allocate (ob_typ (n_read))

      read (10) ob_age(1:n_read)
      read (10) ob_err(1:n_read)
      read (10) ob_flg(1:n_read)
      read (10) ob_lat(1:n_read)
      read (10) ob_lon(1:n_read)
      read (10) ob_qc(1:n_read)
      read (10) ob_typ(1:n_read)
      read (10) ob_sss(1:n_read)
      read (10) ob_sst(1:n_read)
      read (10) ob_dtg(1:n_read)

      if (vrsn .eq. 2) then
         read (10) ob_rcp(1:n_read)
      else
         do i = 1, n_read
         ob_rcp(i) = ob_dtg(i)
         enddo
      endif

      open(21,file='window.txt',status='old')
      read(21,'(a12)') winstart
      read(21,'(a12)') winend
      close(21)

      open(20,file='sss.txt',status='new')

      do i=1, n_read

!     HAT10
      if(ob_lat(i).ge.1.0.and.ob_lat(i).le.50.0.and.
     6     ob_lon(i).ge.-100.0.and.ob_lon(i).le.-7.0) then

!     time window
      if(ob_dtg(i).ge.winstart.and.ob_dtg(i).le.winend) then

      if(ob_dtg(i)(11:12).gt."59") ob_dtg(i)(11:12)="59"

!     Missing ob_qc
      if(ob_qc(i).gt.99.0) ob_qc(i)=99.9
      if(ob_err(i).gt.9.9) ob_err(i)=9.9

      write(20,25) ob_dtg(i),ob_lat(i),ob_lon(i),
     6             ob_sss(i),ob_err(i),ob_qc(i)

      endif ! time window 

      endif ! HAT10

      enddo

25    format(a12,1x,f6.3,1x,f8.3,3(1x,f6.3))
      close(20)

      endif

      return
      end


