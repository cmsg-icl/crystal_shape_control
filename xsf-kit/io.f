      module io
        implicit none
        private
!       NGDM     : Maximum number of grids along x y and z (NGDM*NGDM*NGDM)
!       NATM     : Maximum number of atoms
!       NGDX/Y/Z : Actual rid points along x/y/z
!       NAT      : Actual number of atoms
        integer,parameter :: NGDM = 1000
        integer,parameter :: NATM = 1000
        integer           :: NGDX,NGDY,NGDZ,NAT,NGD,NGDAVG

        public :: read_3dxsf,write_1dtxt,write_3dxsf
!    &    ,NGDX,NGDY,NGDZ,NAT,NGDAVG

        contains
        subroutine read_3dxsf(XSF,LATT,ATLABEL,ATCOORD,ORG,BOX,GRID)
!         Read XCrySDen xsf format 3D grid data.
!         XSF     : Name of XCrySDen XSF file
!         LATT    : 3*3 lattice matrix, in Angstrom
!         ATLABEL : NAT*1 character list of atom species
!         ATCOORD : 3*NAT list of atomic coordinates, in Angstrom
!         ORG     : Origin of data box, in Angstrom
!         BOX     : Matrix of 3D data box, in Angstrom
!         GRID    : NGDX*NGDY*NGDZ grid data. For QE, e/Bohr^3. For VASP, e
          character(len=80),intent(in)                     :: XSF
          character(len=100)                               :: HEADER
          integer                                          :: I,J,K
          real,dimension(3,3),intent(out)                  :: LATT,BOX
          character*2,dimension(:),allocatable,intent(out) :: ATLABEL
          real,dimension(:,:),allocatable,intent(out)      :: ATCOORD
          real,dimension(3),intent(out)                    :: ORG
          real,dimension(:,:,:),allocatable,intent(out)    :: GRID

          open(10,file=XSF,status='OLD',err=1000)
          read(10,'(A)',err=1000,end=1000) HEADER
          do while(index(HEADER,'PRIMVEC') == 0)
            read(10,'(A)',err=1000,end=1000) HEADER
          enddo
!         Read lattice matrix
          read(10,'(3F15.9)',err=1000,end=1000)
     &      ((LATT(I,J),I=1,3),J=1,3)

!         Read atomic species and coords
          read(10,'(A)',err=1000,end=1000) HEADER
          do while(index(HEADER,'PRIMCOORD') == 0)
            read(10,'(A)',err=1000,end=1000) HEADER
          enddo
          read(10,'(2I13)',err=1000,end=1000) NAT,I
          if (NAT > NATM) then
            print*,'Too many atoms. Maximum atoms allowed: ',NATM,
     &        '. Exiting'
            stop
          endif
          allocate(ATLABEL(NAT),ATCOORD(3,NAT))
          read(10,'(A2,4X,3F15.9)',err=1000,end=1000) (ATLABEL(I),
     &      ATCOORD(1,I),ATCOORD(2,I),ATCOORD(3,I),I=1,NAT)

          print*,'3D geometry data read'

!         Read box where 3D data is defined
          read(10,'(A)',err=1000,end=1000) HEADER
          do while(index(HEADER,'BEGIN_DATAGRID_3D') == 0)
            read(10,'(A)',err=1000,end=1000) HEADER
          enddo

!         Read 3D grid data
          read(10,'(3I13)',err=1000,end=1000) NGDX,NGDY,NGDZ
          NGD = NGDX * NGDY * NGDZ
          if (NGDX > NGDM .or. NGDY > NGDM .or. NGDZ > NGDM) then
            print*,'Grid too large. Maximum grid numbers along X/Y/Z: ',
     &        NGDM,'. Exiting.'
            stop
          endif
          read(10,'(3F10.6)',err=1000,end=1000) (ORG(I),I=1,3)
          read(10,'(3F12.6)',err=1000,end=1000) ((BOX(I,J),I=1,3),J=1,3)
          allocate(GRID(NGDX,NGDY,NGDZ))
          read(10,'(6E14.6)',err=1000,end=1001)
     &      (((GRID(I,J,K),I=1,NGDX),J=1,NGDY),K=1,NGDZ)
          print*,'3D grid data read'
          close(10)
          return

1001      print*,'3D grid data read - but probably abnormal',
     &      'termination.';close(10);return
1000      print*,'Error opening or reading the 3D XSF file ',XSF;stop
        end subroutine read_3dxsf
!----
        subroutine write_1dtxt(TXTOUT,AREA,DIST,AVG1D)
!         Write 1D planar-averaged data into a txt file
!         TXTOUT  : Output file name
!         DIST    : Displacement (x axis), in Bohr
!         AVG1D   : Averaged data (y axis). Cross section area normalized to 1
          character(len=80),intent(in) :: TXTOUT
          real,intent(in)              :: AREA
          real,dimension(:),intent(in) :: DIST,AVG1D
          integer                      :: I

          NGDAVG = size(DIST)

          open(20,file=TXTOUT)
          write(20,200) 'N Points',NGDAVG,
     &                  'Step in Bohr',DIST(2) - DIST(1),
     &                  'Cross section area(Bohr**2)',AREA
200       format(A15,I4,4X,A15,F15.6,4X,A30,E15.9)
          write(20,'(A16,4X,A16,4x,A16)') 'x(Bohr)','y(Bohr**-3)'
          write(20,'(F16.8,4X,F16.8,4x,F16.8)') 
     &         (DIST(I),AVG1D(I),I=1,NGDAVG)
          write(20,'(/)')

          close(20)
        end subroutine write_1dtxt
!----
        subroutine write_3dxsf(XSFOUT,LATT,ATLABEL,ATCOORD,ORG,BOX,GRID)
!         Write 3D grid data into a XCrySDen xsf file
!         XSFOUT : Output file name
          character(len=80),intent(in)             :: XSFOUT
          real,dimension(3,3),intent(in)           :: LATT,BOX
          character*2,dimension(:),intent(in)      :: ATLABEL
          real,dimension(:,:),intent(in)           :: ATCOORD
          real,dimension(3),intent(in)             :: ORG
          real,dimension(:,:,:),intent(in)         :: GRID
          integer                                  :: I,J,K

          NAT = size(ATLABEL,dim=1)
          NGDX = size(GRID,dim=1)
          NGDY = size(GRID,dim=2)
          NGDZ = size(GRID,dim=3)

          open(21,file=XSFOUT)
          write(21,'(A8)') ' CRYSTAL'
          write(21,'(A8)') ' PRIMVEC'
          write(21,'(3F15.9)') ((LATT(I,J),I=1,3),J=1,3)
          write(21,'(A10)') ' PRIMCOORD'
          write(21,'(2I12)') NAT,1
          do J = 1,NAT
            write(21,'(A6,3F15.9)') ATLABEL(J),ATCOORD(1:3,J)
          enddo
          write(21,'(A)') 'BEGIN_BLOCK_DATAGRID_3D'
          write(21,'(A)') '3D_XSFDATA'
          write(21,'(A)') 'BEGIN_DATAGRID_3D_UNKNOWN'
          write(21,'(3I12)') NGDX,NGDY,NGDZ
          write(21,'(3F10.6)') (ORG(I),I=1,3)
          write(21,'(3F12.6)') ((BOX(I,J),I=1,3),J=1,3)
          NGD = 0
          do K = 1,NGDZ
            do J = 1,NGDY
              do I = 1,NGDX
                NGD = NGD + 1
                if (mod(NGD,6) == 0) then
                  write(21,'(E14.6)') GRID(I,J,K)
                else
                  write(21,'(E14.6,$)') GRID(I,J,K)
                endif
              enddo
            enddo
          enddo
          write(21,'(A)') 'END_DATAGRID_3D'
          write(21,'(A,/,/)') 'END_BLOCK_DATAGRID_3D'

          close(21)
        end subroutine write_3dxsf
      end module io
