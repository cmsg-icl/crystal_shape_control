      module operation
        implicit none
        private
!       A2BR : Conversion rate from Angstrom to Bohr
!       NGDM : The maximum number of grid points along X/Y/Z
        real,parameter    :: A2BR = 1.889726128
        integer,parameter :: NGDM = 1000

        public :: planar_avg,shift_origin,plane_area

        contains
        subroutine planar_avg(ORG,BOX,GRID,AVGVEC,AREA,DIST,AVG1D)
!         Calculate the planar averaged data along the given direction
!         AVGVEC  : 1,2,3, lattice vectors along which the planar averaged data is computed
!         DIST    : NGDAVG * 1 Plane distances, in Bohr
!         AVG1D   : NGDAVG * 1 Planar averaged data, surface area normalized to 1
          real,dimension(3),intent(in)     :: ORG
          real,dimension(3,3),intent(in)   :: BOX
          real,dimension(:,:,:),intent(in) :: GRID
          integer,intent(in)               :: AVGVEC
          integer                          :: NGDAVG,NGDX,NGDY,NGDZ
          integer                          :: I,J,K
          real                             :: TDIST,DDIST
          real,intent(out)                 :: AREA
          real,dimension(:),allocatable,intent(out) :: DIST,AVG1D

          NGDX = size(GRID,dim=1)
          NGDY = size(GRID,dim=2)
          NGDZ = size(GRID,dim=3)
          NGDAVG = size(GRID,dim=AVGVEC)
          AREA = plane_area(BOX,AVGVEC)

          TDIST = (BOX(1,AVGVEC)**2
     &           + BOX(2,AVGVEC)**2
     &           + BOX(3,AVGVEC)**2)**0.5 * A2BR
          DDIST = TDIST / NGDAVG

          allocate(DIST(NGDAVG),AVG1D(NGDAVG))
          do I = 1,NGDAVG
! Data point at the middle of a slice
            DIST(I) = DDIST * (I - 0.5) + ORG(NGDAVG) * A2BR
! Initialize AVG1D
            AVG1D(I) = 0.
          enddo

          if (AVGVEC == 1) then
            do I = 1,NGDX
              do K = 1,NGDZ
                do J = 1,NGDY
                  AVG1D(I) = AVG1D(I) + GRID(I,J,K) / NGDY / NGDZ
                enddo
              enddo
            enddo
          else if (AVGVEC == 2) then
            do J = 1,NGDY
              do K = 1,NGDZ
                do I = 1,NGDX
                  AVG1D(J) = AVG1D(J) + GRID(I,J,K) / NGDX / NGDZ
                enddo
              enddo
            enddo
          else if (AVGVEC == 3) then
            do K = 1,NGDZ
              do J = 1,NGDY
                do I = 1,NGDX
                  AVG1D(K) = AVG1D(K) + GRID(I,J,K) / NGDX / NGDY
                enddo
              enddo
            enddo
          endif
          print*,'Planar averaged data calculated along ', AVGVEC
        end subroutine planar_avg
        
        subroutine shift_origin(LATT,ATCOORD,AVGVEC,SHIFT,DIST,AVG1D)
!         Shift origin of slab along the averaged direction
!         SHIFT : Shifting length. In Angstrom
          real,dimension(3,3),intent(in)  :: LATT
          real,dimension(:,:),intent(in)  :: ATCOORD
          integer,intent(in)              :: AVGVEC
          real,intent(in)                 :: SHIFT
          integer                         :: NATOM,NPT,I,J
          real                            :: FRAC,FRACMI=2.,FRACMX=-2.,
     &                                       FRACMID,LENVEC=0.,DTPDT,
     &                                       DISP,TMP
          real,dimension(3)               :: VEC
          real,dimension(:),intent(inout) :: DIST,AVG1D

          NATOM = size(ATCOORD,dim=2)
          do I = 1,3
            VEC(I) = LATT(I,AVGVEC) * A2BR
            LENVEC = LENVEC + VEC(I)**2
          enddo
          LENVEC = LENVEC**0.5
          do I = 1,NATOM
            DTPDT = 0.
            do J = 1,3
              DTPDT = DTPDT + VEC(J) / LENVEC * ATCOORD(J,I) * A2BR
            enddo
            FRAC = DTPDT / LENVEC
            if (FRAC < FRACMI) then
              FRACMI = FRAC
            endif
            if (FRAC > FRACMX) then
              FRACMX = FRAC
            endif
          enddo
          
          FRACMID = (FRACMX + FRACMI) / 2
          DISP = -LENVEC * FRACMID
          NPT = size(DIST)
          do I = 1,NPT
            FRAC = DIST(I) / LENVEC - FRACMID
            if (FRAC > 0.5) then
              DIST(I) = DIST(I) + DISP - LENVEC
            else if (FRAC < -0.5) then
              DIST(I) = DIST(I) + DISP + LENVEC
            else
              DIST(I) = DIST(I) + DISP
            endif
            DIST(I) = DIST(I) + SHIFT * A2BR
          enddo
!         Sort DIST,AVG1D
          do I = 1,NPT-1
            do J = I+1,NPT
              if (DIST(I) > DIST(J)) then
                TMP = DIST(I)
                DIST(I) = DIST(J)
                DIST(J) = TMP
                TMP = AVG1D(I)
                AVG1D(I) = AVG1D(J)
                AVG1D(J) = TMP
              endif
            enddo
          enddo
        end subroutine

        function plane_area(BOX,AVGVEC) result(AREA)
!         Calculate the area of the lattice plane defined by 2 base vectors other than AVGVEC
!         AREA : Area of the plane, in Bohr^2
          real,dimension(3,3),intent(in) :: BOX
          integer,intent(in)             :: AVGVEC
          real,dimension(3)              :: CROSP
          integer                        :: PVEC1,PVEC2
          real                           :: AREA

          if (AVGVEC == 1) then
            PVEC1 = 2
            PVEC2 = 3
          else if (AVGVEC == 2) then
            PVEC1 = 1
            PVEC2 = 3
          else if (AVGVEC == 3) then
            PVEC1 = 1
            PVEC2 = 2
          else
            print*,'Averaged direction must be 1, 2, or 3. Exiting.'
            stop
          endif

          CROSP(1)
     &      = BOX(2,PVEC1) * BOX(3,PVEC2) - BOX(3,PVEC1) * BOX(2,PVEC2)
          CROSP(2)
     &      = BOX(3,PVEC1) * BOX(1,PVEC2) - BOX(1,PVEC1) * BOX(3,PVEC2)
          CROSP(3)
     &      = BOX(1,PVEC1) * BOX(2,PVEC2) - BOX(2,PVEC1) * BOX(1,PVEC2)
          AREA
     &      = (CROSP(1)**2 + CROSP(2)**2 + CROSP(3)**2)**0.5 * A2BR**2

          return
        end function plane_area
      end module operation


