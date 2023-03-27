      program opt3dxsf
!     Process 3D real space grid data in XCrySDen XSF format for various
!     applications. Including:
!     1. Difference among various sets of data, such as differential 
!     charge density
!     2. Planar-averaged 1D profile projected along a given lattice
!     vector (a,b,c), such as planar-averaged electrostatic potential
!
!     Note that by default, lengths are reported in Bohr, unless
!     required by specific data formats. For charge and electrostatic
!     potential units, outputs are consistent with input data, i.e., if
!     the charge density input is in e.Bohr^-3, the 1D line profile is
!     in e.Bohr^-1.
!     
!      To launch the executable, the user can either:
!      1. Copy the binary executable into work directory
!      2. Specify the full path of input data
!     ------------------------------------------------------------------
!     Originally edited for VASP5 by Spica.Vir, NWPU. 5th Apr., 2020
!     ------------------------------------------------------------------
!     Revised for VASP5 by Spica.Vir, ICL. 25th Mar.; 14th May., 2021
!     ------------------------------------------------------------------
!     Revised for XCrySDen by Spica.Vir, ICL, 26th Mar., 2023
!     ------------------------------------------------------------------
        use option

        integer           :: OPTNUM
        character(len=80) :: INPUT,OUTPUT,OUTPUT2

        print*,'1. Planar-averaged line profile of 3D XSF data.'
        print*,'2. 3D XSF data differences of multiple files.'
        print*,'3. 3D data difference + line profile.'
        print*,'Please enter your option: '
        read*,OPTNUM

        if (OPTNUM == 1) then
          print*,'Please specify the name of 3D XSF file: '
          read*,INPUT
          print*,'Please specify the name of 1D line profile file: '
          read*,OUTPUT
          call option1(INPUT,OUTPUT)
        else if (OPTNUM == 2) then
          print*,'Please specify the name of main 3D XSF file: '
          read*,INPUT
          print*,'Please specify the name of 3D XSF output: '
          read*,OUTPUT
          call option2(INPUT,OUTPUT)
        else if (OPTNUM == 3) then
          print*,'Please specify the name of main 3D XSF file: '
          read*,INPUT
          print*,'Please specify the name of 3D XSF output: '
          read*,OUTPUT
          print*,'Please specify the name of 1D line profile file: '
          read*,OUTPUT2
          call option3(INPUT,OUTPUT,OUTPUT2)
        else
          print*,'Error: Option not supported. Exiting.'
          stop
        endif
        stop
      end program opt3dxsf