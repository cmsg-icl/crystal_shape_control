      module operation
        implicit none
        private
!       A2BR : Conversion rate from Angstrom to Bohr
!       NGDM : The maximum number of grid points along X/Y/Z
        real,parameter    :: A2BR = 1.889726128
        integer,parameter :: NGDM = 1000

        public :: planar_avg,plane_area

        contains
        subroutine planar_avg(ORG,BOX,GRID,AVGVEC,DIST,AVGDATA)
!         Calculate the planar averaged data along the given direction
!         AVGVEC  : 1,2,3, lattice vectors along which the planar averaged data is computed
!         DIST    : NGDAVG * 1 Plane distances, in Bohr
!         AVGDATA : NGDAVG * 1 Planar averaged data in Unit.Bohr^-1
          real,dimension(3),intent(in)     :: ORG
          real,dimension(3,3),intent(in)   :: BOX
          real,dimension(:,:,:),intent(in) :: GRID
          integer,intent(in)               :: AVGVEC
          integer                          :: NGDAVG,NGDX,NGDY,NGDZ
          integer                          :: I,J,K
          real                             :: AREA,DAREA,TDIST,DDIST
          real,dimension(:),allocatable,intent(out)    :: DIST
          real,dimension(:),allocatable,intent(out)    :: AVGDATA

          NGDX = size(GRID,dim=1)
          NGDY = size(GRID,dim=2)
          NGDZ = size(GRID,dim=3)
          NGDAVG = size(GRID,dim=AVGVEC)
          AREA = plane_area(BOX,AVGVEC)

          TDIST = (BOX(1,AVGVEC)**2
     &           + BOX(2,AVGVEC)**2
     &           + BOX(3,AVGVEC)**2)**0.5 * A2BR
          DDIST = TDIST / NGDAVG

          allocate(DIST(NGDAVG+1),AVGDATA(NGDAVG+1))
          do I = 1,NGDAVG + 1
            DIST(I) = DDIST * (I - 1) + ORG(NGDAVG) * A2BR
            AVGDATA(I) = 0.
          enddo

          if (AVGVEC == 1) then
            DAREA = AREA / NGDY / NGDZ
            do I = 1,NGDX
              do K = 1,NGDZ
                do J = 1,NGDY
                  AVGDATA(I) = AVGDATA(I) + GRID(I,J,K) * DAREA
                enddo
              enddo
            enddo
! force periodic boundary
            AVGDATA(NGDX+1) = AVGDATA(1)
          else if (AVGVEC == 2) then
            DAREA = AREA / NGDX / NGDZ
            do J = 1,NGDY
              do K = 1,NGDZ
                do I = 1,NGDX
                  AVGDATA(J) = AVGDATA(J) + GRID(I,J,K) * DAREA
                enddo
              enddo
            enddo
            AVGDATA(NGDY+1) = AVGDATA(1)
          else if (AVGVEC == 3) then
            DAREA = AREA / NGDX / NGDY
            do K = 1,NGDZ
              do J = 1,NGDY
                do I = 1,NGDX
                  AVGDATA(K) = AVGDATA(K) + GRID(I,J,K) * DAREA
                enddo
              enddo
            enddo
            AVGDATA(NGDZ+1) = AVGDATA(1)
          endif

          print*,'Planar averaged data calculated along ', AVGVEC
        end subroutine planar_avg

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


