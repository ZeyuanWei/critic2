! Copyright (c) 2015 Alberto Otero de la Roza <aoterodelaroza@gmail.com>,
! Ángel Martín Pendás <angel@fluor.quimica.uniovi.es> and Víctor Luaña
! <victor@fluor.quimica.uniovi.es>. 
!
! critic2 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or (at
! your option) any later version.
! 
! critic2 is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
! 
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

! Class for 3d grids and related tools.
module grid3mod
  use hashmod, only: hash
  use iso_c_binding, only: c_ptr
  use param, only: mlen
  implicit none

  private

  !> Information for wannier functions
  type wandat
     integer :: nks !< Number of k-points (lattice vectors)
     integer :: nwan(3) !< Number of lattice vectors
     integer :: nbnd !< Number of bands
     integer :: nspin !< Number of spins
     logical :: useu = .true. !< Use the U transformation to get MLWF
     logical :: sijavail = .false. !< true if the sij checkpoint file available
     logical :: evcavail = .false. !< true if the evc/unkgen files are available
     character(len=mlen) :: fevc !< evc file name
     real*8, allocatable :: kpt(:,:) !< k-points in fract. coords.
     real*8, allocatable :: center(:,:,:) !< wannier function centers (cryst)
     real*8, allocatable :: spread(:,:) !< wannier function spreads (bohr)
     integer, allocatable :: ngk(:) !< number of plane-waves for each k-point
     integer, allocatable :: igk_k(:,:) !< fft reorder
     integer, allocatable :: nls(:) !< fft reorder
     complex*16, allocatable :: u(:,:,:) !< u matrix
  end type wandat

  !> Three-dimensional grid class
  type grid3
     logical :: isinit = .false. !< is the grid initialized?
     logical :: iswan = .false. !< does it have wannier info?
     integer :: mode !< interpolation mode
     integer :: n(3) !< number of grid points in each direction
     real*8, allocatable :: f(:,:,:) !< grid values
     real*8, allocatable :: c2(:,:,:,:) !< cubic coefficients for spline interpolation
     type(wandat) :: wan !< Wannier functions and related information
   contains
     procedure :: end => grid_end !< deallocate all arrays and uninitialize
     procedure :: setmode !< set the interpolation mode of a grid
     procedure :: normalize !< normalize the grid to a given value
     procedure :: from_array3 !< build a grid3 from a 3d array of real numbers
     procedure :: read_cube !< grid3 from a Gaussian cube file
     procedure :: read_bincube !< grid3 from a binary cube file
     procedure :: read_siesta !< grid3 from siesta RHO file
     procedure :: read_abinit !< grid3 from abinit binary file
     procedure :: read_vasp !< grid3 from VASP file (CHG, CHGCAR, etc.)
     procedure :: read_qub !< grid3 from aimpac qub format
     procedure :: read_xsf !< grid3 from xsf (xcrysden) file
     procedure :: read_unkgen !< read a unkgen file created by pw2wannier.x
     procedure :: read_elk !< grid3 from elk file format
     procedure :: interp !< interpolate the grid at an arbitrary point
     procedure :: laplacian !< grid3 as the Laplacian of another grid3
     procedure :: pot !< grid3 as the potential generated by another grid3
     procedure :: gradrho !< grid3 as the gradrho of another grid3
     procedure :: hxx !< grid3 as the Hessian components of another grid3
     procedure :: rotate_qe_evc !< write U-rotated scratch files using QE evc file
     procedure :: get_qe_wnr !< build a Wannier function from the Bloch coeffs (parallel version)
     procedure :: new_eval !< grid3 from an arithmetic expression
  end type grid3
  public :: grid3

  integer, parameter :: mode_nearest = 1 !< interpolation mode: nearest grid node
  integer, parameter :: mode_trilinear = 2 !< interpolation mode: trilinear
  integer, parameter :: mode_trispline = 3 !< interpolation mode: trispline
  integer, parameter :: mode_tricubic = 4 !< interpolation mode: tricubic
  integer, parameter :: mode_default = mode_tricubic

  interface
     module subroutine new_eval(f,sptr,n,expr,fh,field_cube)
       class(grid3), intent(inout) :: f
       type(c_ptr), intent(in) :: sptr
       integer, intent(in) :: n(3)
       character(*), intent(in) :: expr
       type(hash), intent(in) :: fh
       interface
          subroutine field_cube(sptr,n,id,fder,dry,ifail,q)
            import c_ptr
            type(c_ptr), intent(in) :: sptr
            character*(*), intent(in) :: id
            integer, intent(in) :: n(3)
            character*(*), intent(in) :: fder
            logical, intent(in) :: dry
            logical, intent(out) :: ifail
            real*8, intent(out) :: q(n(1),n(2),n(3))
          end subroutine field_cube
       end interface
     end subroutine new_eval
     module subroutine grid_end(f)
       class(grid3), intent(inout) :: f
     end subroutine grid_end
     module subroutine setmode(f,mode)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: mode
     end subroutine setmode
     module subroutine normalize(f,norm,omega)
       class(grid3), intent(inout) :: f
       real*8, intent(in) :: norm, omega
     end subroutine normalize
     module subroutine from_array3(f,g)
       class(grid3), intent(inout) :: f
       real*8, intent(in) :: g(:,:,:)
     end subroutine from_array3
     module subroutine read_cube(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_cube
     module subroutine read_bincube(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_bincube
     module subroutine read_siesta(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_siesta
     module subroutine read_abinit(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_abinit
     module subroutine read_vasp(f,file,omega)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
       real*8, intent(in) :: omega !< Cell volume
     end subroutine read_vasp
     module subroutine read_qub(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_qub
     module subroutine read_xsf(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_xsf
     module subroutine read_unk(f,file,filedn,omega,nou,dochk)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file (spin up or total)
       character*(*), intent(in) :: filedn !< Input file (spin down)
       real*8, intent(in) :: omega
       logical, intent(in) :: nou
       logical, intent(in) :: dochk
     end subroutine read_unk
     module subroutine read_unkgen(f,fchk,funkgen,fevc,omega)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: fchk !< Input file (chk file from wannier90)
       character*(*), intent(in) :: funkgen !< unkgen file (unkgen file from wannier90)
       character*(*), intent(in) :: fevc !< unkgen file (evc file from pw2wannier)
       real*8, intent(in) :: omega !< unit cell
     end subroutine read_unkgen
     module subroutine read_elk(f,file)
       class(grid3), intent(inout) :: f
       character*(*), intent(in) :: file !< Input file
     end subroutine read_elk
     module subroutine interp(f,xi,y,yp,ypp) 
       class(grid3), intent(inout) :: f !< Grid to interpolate
       real*8, intent(in) :: xi(3) !< Target point (cryst. coords.)
       real*8, intent(out) :: y !< Interpolated value
       real*8, intent(out) :: yp(3) !< First derivative
       real*8, intent(out) :: ypp(3,3) !< Second derivative
     end subroutine interp
     module subroutine laplacian(flap,frho,x2c)
       class(grid3), intent(inout) :: flap
       type(grid3), intent(in) :: frho
       real*8, intent(in) :: x2c(3,3)
     end subroutine laplacian
     module subroutine gradrho(fgrho,frho,x2c)
       class(grid3), intent(inout) :: fgrho
       type(grid3), intent(in) :: frho
       real*8, intent(in) :: x2c(3,3)
     end subroutine gradrho
     module subroutine pot(fpot,frho,x2c,isry)
       class(grid3), intent(inout) :: fpot
       type(grid3), intent(in) :: frho
       real*8, intent(in) :: x2c(3,3)
       logical, intent(in) :: isry
     end subroutine pot
     module subroutine hxx(fxx,frho,ix,x2c)
       class(grid3), intent(inout) :: fxx
       type(grid3), intent(in) :: frho
       integer, intent(in) :: ix
       real*8, intent(in) :: x2c(3,3)
     end subroutine hxx
     module subroutine get_qe_wnr(f,ibnd,ispin,luevc,luevc_ibnd,fout)
       class(grid3), intent(in) :: f
       integer, intent(in) :: ibnd
       integer, intent(in) :: ispin
       integer, intent(in) :: luevc(2)
       integer, intent(inout) :: luevc_ibnd(2)
       complex*16, intent(out), optional :: fout(f%n(1),f%n(2),f%n(3),f%wan%nwan(1)*f%wan%nwan(2)*f%wan%nwan(3))
     end subroutine get_qe_wnr
     module subroutine rotate_qe_evc(f,luevc,luevc_ibnd)
       class(grid3), intent(inout) :: f
       integer, intent(out) :: luevc(2)
       integer, intent(out) :: luevc_ibnd(2)
     end subroutine rotate_qe_evc
  end interface

end module grid3mod
