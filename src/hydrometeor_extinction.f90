subroutine hydrometeor_extinction(f,n_lay_cut,xstr,ystr,frq_str,file_ph)

  use kinds
  use vars_atmosphere
  use nml_params, only: verbose, n_moments

  implicit none

  integer, parameter :: &
    mxlyr = 50, &      ! max grid dimension in z
    maxleg = 200

  integer :: jj, nz, n_lay_cut

  integer :: nlegen, nlegencw, nlegenci, nlegenrr, nlegensn, nlegengr, nlegenha

  real(kind=dbl) :: f

  real(kind=dbl) :: kextcw, salbcw, kextrr, salbrr,  &
       kextci, salbci, kextsn, salbsn, kextgr, salbgr,  kextha, salbha, &
       backcw, backrr, backci, backsn, backgr, backha

  real(kind=dbl), dimension(200) :: LEGEN, LEGEN2, LEGEN3, LEGEN4,&
       LEGENcw, LEGENrr, LEGENci, LEGENgr, LEGENsn, LEGENha,      &
       LEGEN2cw, LEGEN2rr, LEGEN2ci, LEGEN2gr, LEGEN2sn, LEGEN2ha,  &
       LEGEN3cw, LEGEN3rr, LEGEN3ci, LEGEN3gr, LEGEN3sn, LEGEN3ha,  &
       LEGEN4cw, LEGEN4rr, LEGEN4ci, LEGEN4gr, LEGEN4sn, LEGEN4ha

  real(kind=dbl), dimension(2) :: P11, ang

  real(kind=dbl), dimension(mxlyr) :: &
       g_coeff,    &
       kexttot,    &
       kextcloud,  &
       kextrain,   &
       kextice,    &
       kextgraupel,&
       kextsnow,   &
       kexthail,   &
       salbtot,    &
       absorp,     & ! might be unnecessary
       back        

  real(kind=dbl) :: threshold ! threshold value for hydrometeor extinction as mass mixing ratio

  character(2) :: nzstr

  character(3), intent(in) :: xstr, ystr

  character(6), intent(in) :: frq_str

  character(64), intent(out) :: file_PH(mxlyr)

  if (verbose .gt. 1) print*, 'Entering hydrometeor_extinction'

  threshold = 1.e-5   ! [kg/kg]

  if (verbose .gt. 0) print*, 'start loop over layer'

  grid_z: do nz = 1, N_lay_cut  ! loop over all layers

      if (verbose .gt. 0) print*, 'Layer: ', nz

      write(nzstr, '(i2.2)') nz

      ! INITIALIZATION OF LEGENDRE COEFFICIENTS  

      nlegen = 0 
      legen   = 0.d0
      legen2  = 0.d0
      legen3  = 0.d0
      legen4  = 0.d0

      !strings with blank spaces            
      FILE_PH(nz) = ''

!---------------------------------------------------------
! calculation of the single scattering properties
! of hydrometeors. cloud water and cloud ice are 
! with respect to radius. whereas the distribution 
! of precipitating particles is with respect to diameter.
!---------------------------------------------------------

!---------------------------------------------------------
!        single scattering properties of cloud water
!---------------------------------------------------------

      nlegencw = 0 
      legencw  = 0.d0
      legen2cw = 0.d0
      legen3cw = 0.d0
      legen4cw = 0.d0

      kextcw = 0.d0 
      salbcw = 0.d0 
      backcw = 0.d0 

      if (cwc_q(nz) .ge. threshold .and. n_moments .eq. 1) then
    	call cloud_ssp(f,cwc_q(nz),temp(nz),press(nz),q_hum(nz),&
    		maxleg, kextcw, salbcw, backcw,  &
            nlegencw, legencw, legen2cw, legen3cw, legen4cw)
      else if (cwc_q(nz) .ge. threshold .and. n_moments .eq. 2) then
    	call cloud_ssp(f,cwc_q(nz),temp(nz),press(nz),q_hum(nz),&
    		maxleg, kextcw, salbcw, backcw,  &
            nlegencw, legencw, legen2cw, legen3cw, legen4cw, cwc_n(nz))
      else
	    kextcw = 0.0d0
	    salbcw = 0.0d0
	    backcw = 0.0d0
      end if

!---------------------------------------------------------
!       single scattering properties of rain
!---------------------------------------------------------

      nlegenrr = 0 
      legenrr  = 0.d0
      legen2rr = 0.d0
      legen3rr = 0.d0
      legen4rr = 0.d0

      kextrr = 0.d0 
      salbrr = 0.d0 
      backrr = 0.d0 

      if (rwc_q(nz) .ge. threshold .and. n_moments .eq. 1) then
	    call rain_ssp(f,rwc_q(nz),temp(nz),press(nz),q_hum(nz),&
		    maxleg,kextrr, salbrr, backrr,  &
            nlegenrr, legenrr, legen2rr, legen3rr, legen4rr)
      else if (rwc_q(nz) .ge. threshold .and. n_moments .eq. 2) then
      	call rain_ssp(f,rwc_q(nz),temp(nz),press(nz),q_hum(nz),&
      		maxleg,kextrr, salbrr, backrr,  &
      		nlegenrr, legenrr, legen2rr, legen3rr, legen4rr, rwc_n(nz))
      else
	    kextrr = 0.0d0
	    salbrr = 0.0d0
	    backrr = 0.0d0
      end if

!---------------------------------------------------------
!       single scattering properties of ice crystals
!---------------------------------------------------------

      nlegenci = 0 
      legenci  = 0.d0
      legen2ci = 0.d0
      legen3ci = 0.d0
      legen4ci = 0.d0

      kextci = 0.0d0 
      salbci = 0.0d0 
      backci = 0.0d0 

      if (iwc_q(nz) .ge. threshold*1.e-2 .and. n_moments .eq. 1) then
	    call ice_ssp(f,iwc_q(nz),temp(nz),press(nz),q_hum(nz),&
		    maxleg,kextci, salbci, backci,  &
            nlegenci, legenci, legen2ci, legen3ci, legen4ci)
      else if (iwc_q(nz) .ge. threshold .and. n_moments .eq. 2) then
      	call ice_ssp(f,iwc_q(nz),temp(nz),press(nz),q_hum(nz),&
      		maxleg,kextci, salbci, backci,  &
      		nlegenci, legenci, legen2ci, legen3ci, legen4ci, iwc_n(nz))
      else
	    kextci = 0.0d0
	    salbci = 0.0d0
	    backci = 0.0d0
      end if

!---------------------------------------------------------
!       single scattering properties of snow
!---------------------------------------------------------

      nlegensn = 0 
      legensn = 0.0d0
      legen2sn = 0.0d0
      legen3sn = 0.0d0
      legen4sn = 0.0d0

      if (swc_q(nz) .ge. threshold .and. n_moments .eq. 1) then
	    call snow_ssp(f,swc_q(nz),temp(nz),press(nz),q_hum(nz),&
		    maxleg,kextsn, salbsn, backsn,  &
            nlegensn, legensn, legen2sn, legen3sn, legen4sn)
        call legendre2phasefunction(legensn, nlegensn, 2, 200,p11, ang)
	    backsn = kextsn * salbsn * P11 (2)
      else if (swc_q(nz) .ge. threshold .and. n_moments .eq. 2) then
      	call snow_ssp(f,swc_q(nz),temp(nz),press(nz),q_hum(nz),&
      		maxleg,kextsn, salbsn, backsn,  &
      		nlegensn, legensn, legen2sn, legen3sn, legen4sn, swc_n(nz))
	    call legendre2phasefunction(legensn, nlegensn, 2, 200,p11, ang)
	    backsn = kextsn * salbsn * P11 (2)
      else
	    kextsn = 0.0d0
	    salbsn = 0.0d0
	    backsn = 0.0d0
      endif

!---------------------------------------------------------
!       single scattering properties of graupel
!---------------------------------------------------------

      nlegengr = 0 
      legengr = 0.0d0
      legen2gr = 0.0d0
      legen3gr = 0.0d0
      legen4gr = 0.0d0

      if (gwc_q(nz) .ge. threshold .and. n_moments .eq. 1) then
		call grau_ssp(f,gwc_q(nz),temp(nz),press(nz),q_hum(nz),&
			maxleg,kextgr, salbgr, backgr,  &
            nlegengr, legengr, legen2gr, legen3gr, legen4gr)
		call legendre2phasefunction(legengr, nlegengr, 2, 200, p11, ang)
			backgr = kextgr * salbgr * p11 (2)
	  else if (gwc_q(nz) .ge. threshold .and. n_moments .eq. 2) then
      	call grau_ssp(f,gwc_q(nz),temp(nz),press(nz),q_hum(nz),&
      		maxleg,kextgr, salbgr, backgr,  &
      		nlegengr, legengr, legen2gr, legen3gr, legen4gr, gwc_n(nz))
      	call legendre2phasefunction(legengr, nlegengr, 2, 200, p11, ang)
			backgr = kextgr * salbgr * p11 (2)
      else
		kextgr = 0.0d0
		salbgr = 0.0d0
		backgr = 0.0d0
      endif

!---------------------------------------------------------
!       single scattering properties of hail
!---------------------------------------------------------

      nlegenha = 0
      legenha = 0.0d0
      legen2ha = 0.0d0
      legen3ha = 0.0d0
      legen4ha = 0.0d0

	  if (n_moments .eq. 2) then
        if (hwc_q(nz) .ge. threshold) then
		  call hail_ssp(f,hwc_q(nz),temp(nz),press(nz),q_hum(nz),&
			  maxleg,kextha, salbha, backha,  &
              nlegenha, legenha, legen2ha, legen3ha, legen4ha, hwc_n(nz))
		  call legendre2phasefunction(legenha, nlegenha, 2, 200, p11, ang)
			  backha = kextha * salbha * p11 (2)
		else
			kextha = 0.0d0
			salbha = 0.0d0
			backha = 0.0d0
		endif
      else
		kextha = 0.0d0
		salbha = 0.0d0
		backha = 0.0d0
      endif

      nlegen = max(nlegen,nlegencw,nlegenci,nlegenrr,nlegensn,nlegengr,nlegenha)

      if (verbose .gt. 0) print*, 'End of scattering calc for layer: ', nz

      !CCCCCCCCCCCCC   END OF SINGLE SCATTERING PROPERTY COMPUTATIONS  CCCCCCC

      !                                                                       
      !           Summing up the scattering parameters and writing the
      !           input file of the scattering properties of each layer
      !                                                                       

      kexttot(nz) = kextcw + kextrr + kextci + kextsn + kextgr + kextha
      kextcloud(nz) = max(0.0d0, kextcw)
      kextrain(nz) = max(0.0d0, kextrr)
      kextice(nz) = max(0.0d0, kextci)
      kextsnow(nz) = max(0.0d0, kextsn)
      kextgraupel(nz) = max(0.0d0, kextgr)
      kexthail(nz) = max(0.0d0, kextha)
      back(nz) = backcw + backrr + backci + backsn + backgr + backha

      if (kexttot(nz) .lt. 0.) write(*,*) 'something wrong'
      if (kexttot(nz) .le. 0.) then 
		salbtot(nz) = 0.0
      else 
		salbtot(nz) = (salbcw * kextcw + salbrr *       &
	      kextrr + salbci * kextci + salbsn * kextsn + salbgr *    &
	      kextgr + salbha * kextha) / kexttot(nz)
      endif

      absorp(nz) = (1.0 - salbtot(nz) ) * kexttot(nz)                                                 

!!!!!!!!!!!!!!!!! check whether hgt_lev needs to be km or m !!!!!!!!!!!!!!!!!

      !   summing up the Legendre coefficient                                 

      if (kexttot(nz) .le. 0.0 .or.    &
		  salbtot(nz) .le. 0.0) then
		FILE_PH(nz) = ''
	!    writing no file                                                                        
      else ! there are hydrometeor present : a PH file is needed

		FILE_PH(nz) = '/tmp/PHx'//xstr//'y'//ystr//'lev'//Nzstr//'f'//frq_str

		open(unit=21, file=file_PH(nz), STATUS='unknown', &
	      form='FORMATTED')
		write(21,*) kexttot(nz), '   EXINCTION'
		write(21,*) kexttot(nz) * salbtot(nz), '   SCATTERING'
		write(21,*) salbtot(nz), '   SINGLE SCATTERING ALBEDO'
		write(21,*) Nlegen - 1, '      DEGREE OF LEGENDRE SERIES'

		do jj = 1, Nlegen

	    	legen (jj) = (legencw (jj) * salbcw * kextcw + legenrr ( &
				jj) * salbrr * kextrr + legenci (jj) * salbci * kextci + &
			legensn (jj) * salbsn * kextsn + legengr (jj) * salbgr * &
				kextgr + legenha (jj) * salbha * kextha) / (salbtot (nz) &
				* kexttot (nz) )

	    	legen2 (jj) = (legen2cw (jj) * salbcw * kextcw +         &
				legen2rr (jj) * salbrr * kextrr + legen2ci (jj) * salbci &
				* kextci + legen2sn (jj) * salbsn * kextsn + legen2gr (  &
				jj) * salbgr * kextgr + legen2ha (jj) * salbha * kextha ) &
				/ (salbtot (nz) * kexttot (nz) )

		    legen3 (jj) = (legen3cw (jj) * salbcw * kextcw +         &
				legen3rr (jj) * salbrr * kextrr + legen3ci (jj) * salbci &
				* kextci + legen3sn (jj) * salbsn * kextsn + legen3gr (  &
				jj) * salbgr * kextgr + legen3ha (jj) * salbha * kextha) &
				/ (salbtot (nz) * kexttot (nz) )

	    	legen4 (jj) = (legen4cw(jj) * salbcw * kextcw +         &
				legen4rr (jj) * salbrr * kextrr + legen4ci (jj) * salbci &
				* kextci + legen4sn (jj) * salbsn * kextsn + legen4gr (  &
				jj) * salbgr * kextgr + legen4ha (jj) * salbha * kextha) &
				/ (salbtot(nz) * kexttot &
				(nz))

	   		write (21, 1005) jj - 1, legen (jj), legen2 (jj),        &
				legen3 (jj), legen4 (jj), legen (jj), legen3 (jj)
	    	g_coeff (nz) = legen (2) / 3.0d0
1005        format  (i3,6(1x,f10.7))

	end do ! end of cycle over Legendre coefficient
	close(21)
      end if
  end do grid_z !end of cycle over the vertical layers

  if (verbose .gt. 1) print*, 'Exiting hydrometeor_extinction'

  return

end subroutine hydrometeor_extinction
