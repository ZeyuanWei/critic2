! Copyright (c) 2007-2018 Alberto Otero de la Roza <aoterodelaroza@gmail.com>,
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

submodule (fieldseedmod) proc
  implicit none

contains

  !> Terminate a field seed and set the field format to unknown.
  module subroutine fieldseed_end(f)
    use param, only: ifformat_unknown
    class(fieldseed), intent(inout) :: f

    f%iff = ifformat_unknown
    f%errmsg = ""
    f%nfile = 0
    if (allocated(f%file)) deallocate(f%file)
    if (allocated(f%piat)) deallocate(f%piat)
    f%n = 0
    f%isry = .false.
    f%ids = ""
    f%ids2 = ""
    f%expr = ""
    f%elseopt = ""
    f%testrmt = .true.
    f%readvirtual = .false.
    f%fid = ""
    f%nou = .false.

  end subroutine fieldseed_end

  !> Parse an input string in critic2 syntax and build a field seed
  !> from it. lp0 is the string pointer (1 by default). In output, lp0
  !> contains the new string pointer (if provided). If withoptions,
  !> read the field options from the input line, too.
  module subroutine fieldseed_parse(f,line,withoptions,lp0)
    use global, only: eval_next
    use types, only: realloc
    use tools_io, only: getword, lower, ferror, equal, isinteger, zatguess,&
       isexpression
    use param, only: dirsep,&
       ifformat_unknown, ifformat_wien, ifformat_elk, ifformat_pi, ifformat_cube,&
       ifformat_bincube, ifformat_abinit,&
       ifformat_vasp, ifformat_vaspchg, ifformat_qub, ifformat_xsf, ifformat_elkgrid,&
       ifformat_siestagrid, ifformat_dftb, ifformat_chk, ifformat_wfn, ifformat_wfx, ifformat_fchk,&
       ifformat_molden, ifformat_as, ifformat_as_promolecular, ifformat_as_core, ifformat_as_lap,&
       ifformat_as_grad, ifformat_as_pot, ifformat_as_clm, ifformat_as_clm_sub, ifformat_copy, &
       ifformat_promolecular, ifformat_promolecular_fragment, ifformat_as_ghost
    class(fieldseed), intent(inout) :: f
    character*(*) :: line
    logical, intent(in) :: withoptions
    integer, intent(inout), optional :: lp0
    
    character(len=:), allocatable :: file, lfile, extdot, extund, word, lword
    integer :: lp, nfile, i, lpo, lpo2
    logical :: ok, nofoundexit, savemid
    
    lp = 1
    if (present(lp0)) lp = lp0
    call f%end()

    call read_next_as_file()

    ! Special keywords to force using a particular format. Also,
    ! handle the copy and promolecular keywords.
    if (equal(lfile,"wien")) then
       f%iff = ifformat_wien
       call read_next_as_file()
    elseif (equal(lfile,"elk")) then
       f%iff = ifformat_elk
       call read_next_as_file()
    elseif (equal(lfile,"pi")) then
       f%iff = ifformat_pi
       call read_next_as_file()
    elseif (equal(lfile,"cube")) then
       f%iff = ifformat_cube
       call read_next_as_file()
    elseif (equal(lfile,"bincube")) then
       f%iff = ifformat_bincube
       call read_next_as_file()
    elseif (equal(lfile,"abinit")) then
       f%iff = ifformat_abinit
       call read_next_as_file()
    elseif (equal(lfile,"vasp")) then
       f%iff = ifformat_vasp
       call read_next_as_file()
    elseif (equal(lfile,"vaspchg")) then
       f%iff = ifformat_vaspchg
       call read_next_as_file()
    elseif (equal(lfile,"qub")) then
       f%iff = ifformat_qub
       call read_next_as_file()
    elseif (equal(lfile,"xsf")) then
       f%iff = ifformat_xsf
       call read_next_as_file()
    elseif (equal(lfile,"elkgrid")) then
       f%iff = ifformat_elkgrid
       call read_next_as_file()
    elseif (equal(lfile,"siesta")) then
       f%iff = ifformat_siestagrid
       call read_next_as_file()
    elseif (equal(lfile,"dftb")) then
       f%iff = ifformat_dftb
       call read_next_as_file()
    elseif (equal(lfile,"chk")) then
       f%iff = ifformat_chk
       call read_next_as_file()
    elseif (equal(lfile,"wfn")) then
       f%iff = ifformat_wfn
       call read_next_as_file()
    elseif (equal(lfile,"wfx")) then
       f%iff = ifformat_wfx
       call read_next_as_file()
    elseif (equal(lfile,"fchk")) then
       f%iff = ifformat_fchk
       call read_next_as_file()
    elseif (equal(lfile,"molden")) then
       f%iff = ifformat_molden
       call read_next_as_file()
    elseif (equal(lfile,"as")) then
       f%iff = ifformat_as
    elseif (equal(lfile,"promolecular")) then
       f%iff = ifformat_promolecular
       call read_next_as_word()
       if (equal(lword,"fragment")) then
          f%iff = ifformat_promolecular_fragment
          call read_next_as_file()
       else
          file = "promolecular"
          call backtrack()
       end if
    elseif (equal(lfile,"copy")) then
       f%iff = ifformat_copy
    end if
    if (len_trim(file) < 1) then
       call f%end()
       f%errmsg = "unexpected input termination"
       return
    end if

    ! detect the field extension
    if (f%iff == ifformat_unknown) then
       if (equal(extdot,'cube')) then
          f%iff = ifformat_cube
       elseif (equal(extdot,'bincube')) then
          f%iff = ifformat_bincube
       else if (equal(extdot,'DEN').or.equal(extund,'DEN').or.equal(extdot,'ELF').or.equal(extund,'ELF').or.&
          equal(extdot,'POT').or.equal(extund,'POT').or.equal(extdot,'VHA').or.equal(extund,'VHA').or.&
          equal(extdot,'VHXC').or.equal(extund,'VHXC').or.equal(extdot,'VXC').or.equal(extund,'VXC').or.&
          equal(extdot,'GDEN1').or.equal(extund,'GDEN1').or.equal(extdot,'GDEN2').or.equal(extund,'GDEN2').or.&
          equal(extdot,'GDEN3').or.equal(extund,'GDEN3').or.equal(extdot,'LDEN').or.equal(extund,'LDEN').or.&
          equal(extdot,'KDEN').or.equal(extund,'KDEN').or.equal(extdot,'PAWDEN').or.equal(extund,'PAWDEN')) then
          f%iff = ifformat_abinit
       else if (equal(extdot,'RHO') .or. equal(extdot,'BADER') .or.&
          equal(extdot,'DRHO') .or. equal(extdot,'LDOS') .or.&
          equal(extdot,'VT') .or. equal(extdot,'VH')) then
          f%iff = ifformat_siestagrid
       else if (equal(extdot,'xml')) then
          f%iff = ifformat_dftb
       else if (equal(extdot,'CHGCAR').or.equal(extdot,'AECCAR0').or.equal(extdot,'AECCAR2')) then
          f%iff = ifformat_vasp
       else if (equal(extdot,'CHG') .or. equal(extdot,'ELFCAR')) then
          f%iff = ifformat_vaspchg
       else if (equal(extdot,'qub')) then
          f%iff = ifformat_qub
       else if (equal(extdot,'xsf')) then
          f%iff = ifformat_xsf
       else if (equal(extdot,'wfn')) then
          f%iff = ifformat_wfn
       else if (equal(extdot,'wfx')) then
          f%iff = ifformat_wfx
       else if (equal(extdot,'fchk')) then
          f%iff = ifformat_fchk
       else if (equal(extdot,'molden')) then
          f%iff = ifformat_molden
       else if (equal(extdot,'clmsum')) then
          f%iff = ifformat_wien
       else if (equal(extdot,'grid')) then
          f%iff = ifformat_elkgrid
       else if (equal(extdot,'OUT')) then
          f%iff = ifformat_elk
       else if (equal(extdot,'ion')) then
          f%iff = ifformat_pi
       else if (equal(extdot,'chk')) then
          f%iff = ifformat_chk
       end if
    end if
    if (f%iff == ifformat_unknown) then
       call f%end()
       f%errmsg = "unknown file format"
       return
    end if

    nfile = 0
    nofoundexit = .true.
    savemid = .false.
    if (f%iff == ifformat_promolecular .or. f%iff == ifformat_as .or. f%iff == ifformat_copy) then
       ! no files needed
       nfile = 0
    elseif (f%iff == ifformat_cube .or. f%iff == ifformat_bincube .or.&
       f%iff == ifformat_abinit .or. f%iff == ifformat_siestagrid .or.&
       f%iff == ifformat_vasp .or. f%iff == ifformat_vaspchg .or. f%iff == ifformat_qub .or.&
       f%iff == ifformat_xsf .or. f%iff == ifformat_wfn .or. f%iff == ifformat_wfx .or.& 
       f%iff == ifformat_fchk .or. f%iff == ifformat_molden .or. f%iff == ifformat_wfx .or.&
       f%iff == ifformat_elkgrid .or. f%iff == ifformat_promolecular_fragment) then
       ! formats for which only one file is needed
       nfile = 1
    elseif (f%iff == ifformat_wien) then
       ! two files are needed
       nfile = 2
    elseif (f%iff == ifformat_dftb) then
       ! three files are needed
       nfile = 3
    elseif (f%iff == ifformat_chk) then
       ! three files are needed
       nfile = 3
       nofoundexit = .true.
    elseif (f%iff == ifformat_elk) then
       ! one, two, or three files are needed
       nfile = 3
       nofoundexit = .false.
    elseif (f%iff == ifformat_pi) then
       ! read many files, with atomic labels/numbers in between
       lpo2 = lpo
       nfile = 0
       inquire(file=file,exist=ok)
       do while (ok)
          nfile = nfile + 1
          word = getword(line,lp)
          call read_next_as_file()
          if (len_trim(file) < 1) exit
          inquire(file=file,exist=ok)
       end do
       lp = lpo2
       call read_next_as_file()
       savemid = .true.
    end if

    ! read the corresponding number of files
    if (nfile > 0) then
       f%nfile = nfile
       allocate(f%file(nfile))
       if (savemid) &
          allocate(f%piat(nfile))
       do i = 1, nfile
          f%file(i) = file
          inquire(file=f%file(i),exist=ok)
          ok = ok .and. (len_trim(file) > 0)
          if (.not.ok) then
             if (nofoundexit .or. i == 1) then
                call f%end()
                f%errmsg = "file not found: " // trim(file)
                return
             else
                call realloc(f%file,i-1)
                nfile = i-1
                f%nfile = nfile
                call backtrack()
                exit
             end if
          end if
          if (savemid) then
             f%piat(i) = getword(line,lp)
          end if
          if (i < nfile) &
             call read_next_as_file()
       end do
    end if

    ! handle the special syntax: load copy
    if (f%iff == ifformat_copy) then
       allocate(f%file(2))
       call read_next_as_word()
       if (len_trim(word) < 1) then
          call f%end()
          f%errmsg = "COPY: first field not found"
          return
       end if
       f%file(1) = trim(word)

       call read_next_as_word()
       if (equal(lword,"to")) then
          call read_next_as_word()
          if (len_trim(word) < 1) then
             call f%end()
             f%errmsg = "COPY: second field not found"
             return
          end if
          f%nfile = 2
          f%file(2) = trim(word)
       else
          f%nfile = 1
          call realloc(f%file,1)
          call backtrack()
       end if
    end if

    ! handle the special syntax: load as
    if (f%iff == ifformat_as) then
       call read_next_as_word()
       if (equal(lword,"promolecular") .or. equal(lword,"core")) then
          if (equal(lword,"promolecular")) then
             f%iff = ifformat_as_promolecular
          else
             f%iff = ifformat_as_core
          end if
          call read_next_as_word()
          if (equal(lword,"sizeof")) then
             call read_next_as_word()
             if (len_trim(word) < 1) then
                call f%end()
                f%errmsg = "wrong sizeof in load as"
                return
             end if
             f%ids = word
          else
             call backtrack()
             ok = eval_next(f%n(1),line,lp)
             ok = ok .and. eval_next(f%n(2),line,lp)
             ok = ok .and. eval_next(f%n(3),line,lp)
             if (.not.ok) then
                call f%end()
                f%errmsg = "wrong size specification in load as"
                return
             end if
          end if
       elseif (equal(lword,"lap") .or. equal(lword,"grad") .or. equal(lword,"pot")) then
          if (equal(lword,"lap")) then
             f%iff = ifformat_as_lap
          elseif (equal(lword,"grad")) then
             f%iff = ifformat_as_grad
          else
             f%iff = ifformat_as_pot
          end if
          call read_next_as_word()
          if (len_trim(word) < 1) then
             call f%end()
             f%errmsg = "wrong field id in load as"
             return
          end if
          f%ids = word
          if (f%iff == ifformat_as_pot) then
             call read_next_as_word()
             if (equal(lword,"ry") .or. equal(lword,"rydberg")) then
                f%isry = .true.
             else
                call backtrack()
             end if
          end if

       elseif (equal(lword,"clm")) then
          call read_next_as_word()
          if (equal(lword,"add")) then
             f%iff = ifformat_as_clm
          elseif (equal(lword,"sub")) then
             f%iff = ifformat_as_clm_sub
          else
             call f%end()
             f%errmsg = "wrong keyword in load as clm"
             return
          end if

          call read_next_as_word()
          f%ids = word
          call read_next_as_word()
          f%ids2 = word
          if (len_trim(f%ids) < 1 .or. len_trim(f%ids2) < 1) then
             call f%end()
             f%errmsg = "wrong field id in load as clm"
             return
          end if
       else
          ! must be an expression
          call backtrack()
          f%iff = ifformat_as
          ok = isexpression(word,line,lp)
          if (.not.ok .or. len_trim(word) < 1) then
             call f%end()
             f%errmsg = "wrong expression in load as"
             return
          end if
          f%expr = word
          call read_next_as_word()
          if (equal(lword,"sizeof")) then
             call read_next_as_word()
             if (len_trim(word) < 1) then
                call f%end()
                f%errmsg = "wrong sizeof in load as"
                return
             end if
             f%ids = word
          elseif (equal(lword,"ghost")) then
             f%iff = ifformat_as_ghost
          else
             call backtrack()
             ok = eval_next(f%n(1),line,lp)
             if (ok) then
                ok = ok .and. eval_next(f%n(2),line,lp)
                ok = ok .and. eval_next(f%n(3),line,lp)
                if (.not.ok) then
                   call f%end()
                   f%errmsg = "wrong size specification in load as"
                   return
                end if
             else
                call backtrack()
                f%iff = ifformat_as_ghost
             end if
          end if
       end if
    end if

    if (withoptions) then
       call f%parse_options(line,lp)
       if (len_trim(f%errmsg) > 0) return
    end if
  
    if (present(lp0)) lp0 = lp

  contains

    subroutine read_next_as_word()
      lpo = lp
      word = getword(line,lp)
      lword = lower(word)
    end subroutine read_next_as_word

    subroutine read_next_as_file()
      lpo = lp
      file = getword(line,lp)
      lfile = lower(file)
      word = file(index(file,dirsep,.true.)+1:)
      extdot = word(index(word,'.',.true.)+1:)
      word = file(index(file,dirsep,.true.)+1:)
      extund = word(index(word,'_',.true.)+1:)
    end subroutine read_next_as_file

    subroutine backtrack()
      lp = lpo
    end subroutine backtrack

  end subroutine fieldseed_parse

  !> Parse field options from a command.
  module subroutine fieldseed_parse_options(f,line,lp0)
    use global, only: eval_next
    use tools_io, only: getword, isexpression_or_word, lower, equal, zatguess, isinteger
    use param, only: ifformat_as_promolecular
    class(fieldseed), intent(inout) :: f
    character*(*) :: line
    integer, intent(inout), optional :: lp0

    integer :: lp, lp2, idum, inum
    character(len=:), allocatable :: lword, word, word2, word3
    logical :: ok

    lp = 1
    if (present(lp0)) lp = lp0

    f%elseopt = ""
    do while(.true.)
       word = getword(line,lp)
       if (len_trim(word) < 1) exit
       lword = lower(word)
       
       if (equal(lword,'nearest').or.equal(lword,'trilinear').or.equal(lword,'trispline').or.&
          equal(lword,'tricubic').or.equal(lword,'exact').or.equal(lword,'approximate').or.&
          equal(lword,'rhonorm').or.equal(lword,'vnorm').or.equal(lword,'core').or.&
          equal(lword,'nocore').or.equal(lword,'numerical').or.equal(lword,'analytical')) then
          ! single-word elsewhere options
          f%elseopt = trim(f%elseopt) // " " // word
       elseif (equal(lword,'typnuc').or.equal(lword,'normalize')) then
          ! option+expression elsewhere options
          ok = isexpression_or_word(word2,line,lp)
          if (.not.ok) then
             call f%end()
             f%errmsg = "wrong " // lword // " syntax"
             return
          end if
          f%elseopt = trim(f%elseopt) // " " // lword // " " // word2
       elseif (equal(lword,'zpsp')) then
          inum = 0
          f%elseopt = trim(f%elseopt) // " zpsp"
          do while (.true.)
             lp2 = lp
             word2 = getword(line,lp)
             if (len_trim(word2) > 0 .and. len_trim(word2) <= 2) then
                if (zatguess(word2) > 0) then
                   inum = inum + 1
                   word3 = getword(line,lp)
                   if (.not.isinteger(idum,word3)) then
                      f%errmsg = "wrong syntax in ZPSP"
                      return
                   end if
                   f%elseopt = trim(f%elseopt) // " " // word2 // " " // word3
                else
                   lp = lp2
                   exit
                end if
             else
                lp = lp2
                exit
             end if
          end do
          if (inum == 0) then
             f%errmsg = "no atoms given in zpsp"
             return
          end if
       elseif (equal(lword,'notestmt')) then
          ! do not test rmt in wien/elk fields
          f%testrmt = .false.
       elseif (equal(lword,'readvirtual')) then
          ! do not test rmt in wien/elk fields
          f%readvirtual = .true.
       elseif (equal(lword,'name').or.equal(lword,'id')) then
          ! name/id of the field
          f%fid = getword(line,lp)
          if (len_trim(f%fid) < 1) then
             call f%end()
             f%errmsg = "missing field name/id"
             return
          end if
       elseif (equal(lword,'fragment')) then
          ! load as promolecular fragment
          if (.not.f%iff == ifformat_as_promolecular) then
             call f%end()
             f%errmsg = "fragment keyword incompatible with this field type"
             return
          end if
          f%nfile = 1
          if (allocated(f%file)) deallocate(f%file)
          allocate(f%file(1))
          f%file(1) = getword(line,lp)
          if (len_trim(f%file(1)) < 1) then
             call f%end()
             f%errmsg = "missing file name in fragment"
             return
          end if
       elseif (equal(lword,'nou')) then
          ! wannier option: nou
          f%nou = .true.
       else
          call f%end()
          f%errmsg = "unknown load keyword: " // word
          return
       end if
    end do
    
    if (present(lp0)) lp0 = lp

  end subroutine fieldseed_parse_options

end submodule proc
