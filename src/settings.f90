module settings
    ! Description:
    ! Definition of all command line and name list paramters for pamtra
    ! and global settings!

    use kinds
    use report_module
    implicit none
    save

    !!Global Stettings
    integer, parameter :: MAXV = 64,   &
    MAXLAY = 600, &
    maxleg = 200, &
    maxfreq = 100, &
    nummu = 16, & ! no. of observation angles
    NSTOKES = 2
    
    integer, parameter :: SRC_CODE = 2,&
    NUMAZIMUTHS = 1,&
    Aziorder = 0

    real(kind=dbl), parameter :: DIRECT_FLUX = 0._dbl ,&
    DIRECT_MU   = 0._dbl

    character(1), parameter :: QUAD_TYPE = 'L',&
    DELTAM = 'N'

    character(1), parameter :: units='T'

    
    ! set by command line options
    integer(kind=long) :: nfrq

    real(kind=dbl) :: obs_height     ! upper level output height [m] (> 100000. for satellite)
    real(kind=dbl) :: emissivity
    real(kind=dbl) :: salinity         ! sea surface salinity
!     double precision, dimension(maxfreq) :: freqs
    real(kind=dbl), dimension(maxfreq) :: freqs

    real(kind=dbl), dimension(nummu) :: mu_values, quad_weights

    integer(kind=long) :: radar_nfft !number of FFT points in the Doppler spectrum [typically 256 or 512]
    integer(kind=long):: radar_no_Ave !number of average spectra for noise variance reduction, typical range [1 40]
    integer(kind=long):: radar_airmotion_linear_steps !for linear air velocity model, how many staps shall be calculated?
    integer(kind=long):: radar_aliasing_nyquist_interv !how many additional nyquists intervalls shall be added to the spectrum to deal with aliasing effects
    integer(kind=long) :: radar_nPeaks
    real(kind=dbl) :: radar_max_V !MinimumNyquistVelocity in m/sec
    real(kind=dbl) :: radar_min_V !MaximumNyquistVelocity in m/sec
    real(kind=dbl) :: radar_pnoise0 !radar noise at 1km
    real(kind=dbl) :: radar_airmotion_vmin
    real(kind=dbl) :: radar_airmotion_vmax
    real(kind=dbl) :: radar_airmotion_step_vmin
    real(kind=dbl) :: radar_min_spectral_snr !threshold for peak detection
    real(kind=dbl) :: radar_K2
    real(kind=dbl) :: radar_receiver_uncertainty_std
    real(kind=dbl) :: hydro_softsphere_min_density !tmatrix method numerically unstable for extremely low density
    real(kind=dbl) :: radar_receiver_miscalibration !radar calibration offset in dB
    real(kind=dbl) :: hydro_threshold, radar_noise_distance_factor

  integer, parameter :: maxnleg = 200 !max legnth of legendre series
  logical, parameter :: lphase_flag = .true.

  logical :: in_python !are we in python

  logical :: lgas_extinction, &    ! gas extinction desired
       lhyd_absorption, &    ! hydrometeor extinction desired
       lhyd_scattering, &    ! hydrometeor scattering desired
       lhyd_emission, &    ! hydrometeor emission desired
       write_nc, &  ! write netcdf or ascii output
       active, &  	   ! calculate active stuff
       passive, &     ! calculate passive stuff (with RT4)
       radar_airmotion, &   ! apply vertical air motion
       radar_save_noise_corrected_spectra, & !remove the noise from the calculated spectrum again (for testing)
       radar_use_hildebrand,&  ! use Hildebrand & Sekhon for noise estimation as a real radar would do. However, since we set the noise (radar_pnoise0) we can skip that.
       radar_convolution_fft,&!use fft for convolution of spectrum
       save_psd, &
       hydro_includeHydroInRhoAir, &
       save_ssp, &
       radar_smooth_spectrum, &
       hydro_fullSpec, &
       hydro_limit_density_area, &
       hydro_adaptive_grid, & ! apply an adaptive grid to the psd. good to reduce mass overestimations for small amounts. works only for modified gamma
       add_obs_height_to_layer, &
       radar_use_wider_peak, & ! use wider peak inlcuding the found noise/peak border
       liblapack ! use liblapack for matrix inversion which much faster

  character(3) :: gas_mod
  character(3) :: liq_mod
  character(20) :: moments_file,file_desc
  character(300) :: output_path, data_path
  character(100) :: creator
  character(18) :: freq_str
  character(2) :: OUTPOL
  character(1) :: GROUND_TYPE
  character(8) :: radar_airmotion_model, radar_mode
  character(10) :: radar_attenuation
  character(15) :: radar_polarisation
  character(2), dimension(5) :: radar_pol
  character(1), dimension(5) :: att_pol
  integer(kind=long):: radar_npol, att_npol


  character(300)  :: input_pathfile        ! name and path of profile
  character(300)  :: input_file        ! name of profile
  character(300) :: namelist_file     ! name of nml_file
  character(300) :: nc_out_file       ! name of netcdf output file
  character(9) :: frq_str_s,frq_str_e
  character(8), dimension(maxfreq) :: frqs_str
  character(300) :: descriptor_file_name
  character(10) :: tmatrix_db
  character(300) :: tmatrix_db_path

  integer(kind=long) :: noutlevels ! number of output levels per profile
  integer(kind=long) :: radar_nfft_aliased, radar_maxTurbTerms !are gained from radar_aliasing_nyquist_interv and radar_nfft

  integer(kind=long) :: randomseed !random seed, 0 means time dependence
contains

  subroutine settings_read(errorstatus)

    use kinds

    implicit none

    logical :: file_exists
    integer(kind=long), intent(out) :: errorstatus
    integer(kind=long) :: err
    character(len=80) :: msg
    character(len=14) :: nameOfRoutine = 'settings_read'


        ! name list declarations
        namelist /SETTINGS/ &
        write_nc, &
        data_path,&
        save_psd, &
        save_ssp, &
        obs_height, &
        outpol, &
        freq_str,&
        file_desc,&
        creator, &
        noutlevels, &
        add_obs_height_to_layer, &
        active, &
        passive,&
        radar_mode, &
        randomseed, &
        ground_type, &
        salinity, &
        emissivity, &
        lgas_extinction, &
        lhyd_absorption, &
        lhyd_scattering, &   
        lhyd_emission, &    
        gas_mod, &
        hydro_fullSpec, &
        hydro_limit_density_area,&
        hydro_softsphere_min_density, &
        hydro_adaptive_grid, &
        tmatrix_db, &
        tmatrix_db_path, &
        liq_mod, &
        hydro_includeHydroInRhoAir,&
        hydro_threshold, &
	radar_nfft, &
	radar_no_Ave, &
	radar_max_V, &
	radar_min_V, &
        radar_pnoise0, &
        radar_airmotion,&
        radar_airmotion_model,&
        radar_airmotion_vmin,&
        radar_airmotion_vmax,&
        radar_airmotion_linear_steps,&
        radar_airmotion_step_vmin,&
        radar_aliasing_nyquist_interv,&
        radar_save_noise_corrected_spectra,&
        radar_use_hildebrand,&
        radar_min_spectral_snr,&
        radar_convolution_fft,&
        radar_K2,&
        radar_noise_distance_factor,&
        radar_receiver_uncertainty_std,&
        radar_receiver_miscalibration, &
        radar_nPeaks,&
        radar_smooth_spectrum,&
        radar_attenuation,&
        radar_polarisation, &
        liblapack
        
      err = 0

     if (verbose >= 3) print*,'Start of ', nameOfRoutine

      ! first put default values
      call settings_fill_default()
  
      if (namelist_file /= "None") then

        INQUIRE(FILE=namelist_file, EXIST=file_exists)   ! file_exists will be TRUE if the file
        call assert_true(err,file_exists,&
            "file "//TRIM(namelist_file)//" does not exist") 

       if (err /= 0) then
          msg = 'value in settings not allowed'
          call report(err, msg, nameOfRoutine)
          errorstatus = err
          return
       end if
       print*, 2    

       if (verbose >= 3) print*,'Open namelist file: ', namelist_file
       ! read name list parameter file
       open(7, file=namelist_file,delim='APOSTROPHE')
       read(7,nml=SETTINGS)
       close(7)

    else
       if (verbose >= 3) print*,'No namelist file to read!', namelist_file
    end if

    call add_settings(err)
    if (err /= 0) then
       msg = 'error in add_settings!'
       call report(err, msg, nameOfRoutine)
       errorstatus = err
       return
    end if

    call test_settings(err)
    if (err /= 0) then
       msg = 'error in test_settings!'
       call report(err, msg, nameOfRoutine)
       errorstatus = err
       return
    end if

    errorstatus = err
    if (verbose >= 3) print*,'End of ', nameOfRoutine
    return
  end subroutine settings_read

  subroutine test_settings(errorstatus)
    use kinds
    implicit none
    integer(kind=long), intent(out) :: errorstatus
    integer(kind=long) :: err = 0
    character(len=80) :: msg
    character(len=15) :: nameOfRoutine = 'test_settings'
    !test for settings go here
    
    err = 0

    if (verbose >= 4) print*,'Start of ', nameOfRoutine
    call assert_true(err, noutlevels > 0, 'Number of output levels has to be larger than 0')
    call assert_false(err,MOD(radar_nfft, 2) == 1,&
         "radar_nfft has to be even") 
    call assert_true(err,(gas_mod == "L93") .or. (gas_mod == "R98"),&
         "gas_mod has to be L93 or R98") 
    if (hydro_fullSpec) then
       call assert_true(err,in_python,&
            "hydro_fullSpec works only in python!") 
    end if
    if (.not. radar_use_hildebrand) then
       call assert_true(err,(radar_noise_distance_factor>0),&
            "radar_noise_distance_factor must be larger when not using Hildebrand!") 
    end if

    if (err /= 0) then
       msg = 'value in settings not allowed'
       call report(err, msg, nameOfRoutine)
       errorstatus = err
       return
    end if

    errorstatus = err
    if (verbose >= 4) print*,'End of ', nameOfRoutine
    return

  end subroutine test_settings

  subroutine add_settings(errorstatus)

    use kinds
    use rt_utilities, &
         only: double_gauss_quadrature,&
         lobatto_quadrature,&
         gauss_legendre_quadrature 

    implicit none

    integer(kind=long) :: i, j, pos1, pos2

    integer(kind=long), intent(out) :: errorstatus
    integer(kind=long) :: err = 0
    character(len=80) :: msg
    character(len=15) :: nameOfRoutine = 'add_settings'

    !additional variables derived from others go here

    if (verbose >= 4) print*,'Start of ', nameOfRoutine

    ! calculate the quadrature angles and weights used in scattering calculations and radiative transfer

    if (quad_type(1:1) .eq. 'D') then
       call double_gauss_quadrature(nummu, mu_values, quad_weights)
    else if (quad_type(1:1) .eq. 'L') then
       call lobatto_quadrature(nummu, mu_values, quad_weights)
    else if (quad_type(1:1) .eq. 'E') then
       j = nummu
       do i = nummu, 1, -1
          if (mu_values(i) .ne. 0.0) then
             quad_weights(i) = 0.0
             j = i - 1
          endif
       enddo
       call gauss_legendre_quadrature(j, mu_values, quad_weights)
    else
       call gauss_legendre_quadrature(nummu, mu_values, quad_weights)
    endif

    !mix some variables to make new ones:
    radar_nfft_aliased = radar_nfft *(1+2*radar_aliasing_nyquist_interv)
    radar_maxTurbTerms = radar_nfft_aliased * 12

    !in python some options are missing. The output levels have already been added by reScaleHeights module of pyPamtra
    if (in_python) add_obs_height_to_layer = .false.

    !process radar_polarisation

    radar_npol = 0
    radar_pol = ""
    pos1 = 1
    pos2 = 1
    DO
       pos2 = INDEX(radar_polarisation(pos1:), ",")
       IF (pos2 == 0) THEN
          radar_npol = radar_npol + 1
          radar_pol(radar_npol) = radar_polarisation(pos1:)
          EXIT
       END IF
       radar_npol = radar_npol + 1
       radar_pol(radar_npol) = radar_polarisation(pos1:pos1+pos2-2)
       pos1 = pos2+pos1
    END DO

    if (verbose > 5) print*, radar_npol, radar_pol, " old string: ", radar_polarisation

    !   as of now, pol for att_hydro is not implemented
    att_npol = 1
    att_pol(1) = "N"

    errorstatus = err
    if (verbose > 3) call print_settings()
    if (verbose >= 4) print*,'End of ', nameOfRoutine
    return

  end subroutine add_settings

  subroutine settings_fill_default

    use kinds

    implicit none

    character(len=14) :: nameOfRoutine = 'settings_fill_default'

    if (verbose >= 2) print*,'Start of ', nameOfRoutine

        !set namelist defaults!
        hydro_threshold = 1.d-20   ! [kg/kg] 
        write_nc=.true.
        data_path='data/'
        save_psd=.false.
        save_ssp=.false.
        noutlevels=2 ! number of output levels
        outpol='VH'
        freq_str=''
        file_desc=''
        creator='Pamtrauser'
        add_obs_height_to_layer = .false.
        active=.true.
        passive=.true.
        radar_mode="simple" !|"moments"|"spectrum"
        randomseed = 0
        ground_type='L'
        salinity=33.0
        emissivity=0.6
        lgas_extinction=.true.
        gas_mod='R98'
        lhyd_absorption=.true.
        lhyd_scattering=.true.
        lhyd_emission=.true.
        hydro_includeHydroInRhoAir = .true.
        hydro_fullSpec = .false.
        hydro_limit_density_area = .true.
        hydro_softsphere_min_density = 10. !kg/m^3
        hydro_adaptive_grid = .true.
        liq_mod = "Ell"
        tmatrix_db = "none" ! none or file
        tmatrix_db_path = "database/"
        radar_polarisation = "NN" ! comma spearated list "NN,HV,VH,VV,HH", translated into radar_pol array
        !number of FFT points in the Doppler spectrum [typically 256 or 512]
        radar_nfft=256
        !number of average spectra for noise variance reduction, typical range [1 150]
        radar_no_Ave=150
        !MinimumNyquistVelocity in m/sec
        radar_max_V=7.885
        !MaximumNyquistVelocity in m/sec
        radar_min_V=-7.885
        !radar noise at 1km in same unit as Ze 10*log10(mm⁶/m³). noise is calculated with noise = radar_pnoise0 + 20*log10(range/1000)
        radar_pnoise0=-32.23 ! mean value for BArrow MMCR during ISDAC

        radar_airmotion = .false.
        radar_airmotion_model = "step" !"constant","linear","step"
        radar_airmotion_vmin = -4.d0
        radar_airmotion_vmax = +4.d0
        radar_airmotion_linear_steps = 30
        radar_airmotion_step_vmin = 0.5d0

        radar_aliasing_nyquist_interv = 1
        radar_save_noise_corrected_spectra = .false.
        radar_use_hildebrand = .false.
        radar_min_spectral_snr = 1.2!threshold for peak detection. if radar_no_Ave >> 150, it can be set to 1.1
        radar_convolution_fft = .true. !use fft for convolution of spectrum. is alomst 10 times faster, but can introduce aretfacts for radars with *extremely* low noise levels or if noise is turned off at all.
        radar_K2 = 0.93 ! dielectric constant |K|² (always for liquid water by convention) for the radar equation
        radar_noise_distance_factor = 1.25
        radar_receiver_uncertainty_std = 0.d0 !dB
        radar_receiver_miscalibration =  0.d0 !dB
        radar_nPeaks = 1 !number of peaks the radar simulator is looking for
        radar_smooth_spectrum = .true.
        radar_attenuation = "disabled" ! "bottom-up" or "top-down"
        radar_use_wider_peak = .false.
        liblapack = .true.

        ! create frequency string if not set in pamtra
        if (freq_str == "") then
             ! get integer and character frequencies
            frq_str_s = "_"//frqs_str(1)
            if (nfrq .eq. 1) then
                frq_str_e = ""
            else
                frq_str_e = "-"//frqs_str(nfrq)
            end if
            freq_str = frq_str_s//frq_str_e
            
        end if 
    
    
    
    end subroutine settings_fill_default
    
    !for debuging
    subroutine print_settings()

      print*, 'noutlevels: ', noutlevels
      print*, 'add_obs_height_to_layer: ', add_obs_height_to_layer
      print*, 'radar_nfft: ', radar_nfft
      print*, 'radar_polarisation: ', radar_polarisation
      print*, 'creator: ', creator
      print*, 'radar_mode: ', radar_mode
      print*, 'radar_pnoise0: ', radar_pnoise0
      print*, 'data_path: ', data_path
      print*, 'radar_min_spectral_snr: ', radar_min_spectral_snr
      print*, 'radar_aliasing_nyquist_interv: ', radar_aliasing_nyquist_interv
      print*, 'radar_airmotion_linear_steps: ', radar_airmotion_linear_steps
      print*, 'radar_airmotion: ', radar_airmotion
      print*, 'ground_type: ', ground_type
      print*, 'write_nc: ', write_nc
      print*, 'outpol: ', outpol
      print*, 'radar_no_ave: ', radar_no_ave
      print*, 'hydro_includeHydroInRhoAir: ', hydro_includeHydroInRhoAir
      print*, 'passive: ', passive
      print*, 'radar_airmotion_model: ', radar_airmotion_model
      print*, 'tmatrix_db_path: ', tmatrix_db_path
      print*, 'tmatrix_db: ', tmatrix_db
      print*, 'lgas_extinction: ', lgas_extinction
      print*, 'gas_mod: ', gas_mod
      print*, 'liq_mod: ', liq_mod
      print*, 'moments_file: ', moments_file
      print*, 'radar_receiver_uncertainty_std: ', radar_receiver_uncertainty_std
      print*, 'radar_receiver_miscalibration: ', radar_receiver_miscalibration
      print*, 'hydro_threshold: ', hydro_threshold
      print*, 'hydro_fullSpec: ', hydro_fullSpec
      print*, 'hydro_limit_density_area: ', hydro_limit_density_area
      print*, 'hydro_softsphere_min_density: ', hydro_softsphere_min_density
      print*, 'hydro_adaptive_grid: ', hydro_adaptive_grid
      print*, 'radar_noise_distance_factor: ', radar_noise_distance_factor
      print*, 'radar_airmotion_step_vmin: ', radar_airmotion_step_vmin
      print*, 'radar_use_hildebrand: ', radar_use_hildebrand
      print*, 'radar_convolution_fft: ', radar_convolution_fft
      print*, 'radar_smooth_spectrum', radar_smooth_spectrum
      print*, 'radar_attenuation', radar_attenuation
      print*, 'radar_use_wider_peak', radar_use_wider_peak
      print*, 'active: ', active
      print*, 'radar_max_v: ', radar_max_v
      print*, 'radar_save_noise_corrected_spectra: ', radar_save_noise_corrected_spectra
      print*, 'lhyd_absorption: ', lhyd_absorption
      print*, 'lhyd_emission: ', lhyd_emission
      print*, 'lhyd_scattering: ', lhyd_scattering
      print*, 'radar_k2: ', radar_k2
      print*, 'radar_nPeaks', radar_nPeaks
      print*, 'salinity: ', salinity
      print*, 'radar_airmotion_vmax: ', radar_airmotion_vmax
      print*, 'radar_min_v: ', radar_min_v
      print*, 'freq_str: ', freq_str
      print*, 'file_desc: ', file_desc
      print*, 'radar_airmotion_vmin: ', radar_airmotion_vmin
      print*, 'emissivity: ', emissivity
      print*, 'save_psd: ', save_psd
      print*, 'save_ssp: ', save_ssp
      print*, "randomseed", randomseed
      print*, "radar_pol", radar_pol
      print*, "radar_npol", radar_npol
      print*, "radar_nfft_aliased", radar_nfft_aliased
      print*, "radar_maxTurbTerms", radar_maxTurbTerms
      print*, "liblapack", liblapack

    end subroutine print_settings
    
end module settings
