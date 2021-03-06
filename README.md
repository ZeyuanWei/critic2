# Critic2
## Overview

Critic2 is a program for the manipulation and analysis of structures
and chemical information in molecules and periodic solids. Critic2 can
be used to read and transform between file formats, and to perform
operations on molecular and crystal structures. In addition, critic2
can read, analyze, and manipulate multiple scalar fields,
three-dimensional functions that take a value at each point in space,
such as the electron density, the spin density, the ELF, etc. An
important part of critic2 is the topological anaylisis of real-space
scalar fields, which includes the implementation of Bader's atoms in
molecules theory: critical point search, basin integration, basin
plotting, etc. Other related techniques, such as non-covalent
interaction plots (NCIplots), are also implemented. Although the
electron density is the usual field critic2 works with, any other
field (ELF, molecular electrostatic potential,...) can be analyzed
using the same techniques. Hence, it is possible to compute, for
instance, the charges inside the basins of ELF, or the gradient paths
of the molecular electrostatic potential. New scalar fields can be
computed using critic2's powerful arithmetic expressions.

Critic2 is designed to provide an abstraction layer on top of the
underlying electronic structure calculation. Different electronic
structure methods (FPLAPW, pseudopotentials, local orbitals,...)
represent the electron density, and other fields, in different
ways. The program interfaces to many of these and applies common
techniques and algorithms to them. At present, critic2 can interface
to WIEN2k, elk, PI, Quantum ESPRESSO, abinit, VASP, DFTB+, Gaussian,
psi4, siesta, and to any other program capable of writing the scalar
field of interest to a grid. Many more structural file formats are
supported, and critic2 provides basic crystallographic and structural
computing tools (e.g. crystal structure comparison, molecular
environment generation, file conversion).

## Files

* README: this file.
* AUTHORS: the authors of the package.
* LICENSE: a copy of the licence. Critic2 is distributed under the
  GNU/GPL license v3.
* INSTALL: installation instructions. These are automatically
  generated by autoconf. See below for more specific instructions. 
* THANKS: acknowledgements. Please read this for details on the
  license of code that critic2 uses.
* src/: source code. The critic2 binary is generated in here.
* doc/: manual (user-guide.txt) and syntax reference (syntax.txt). You
        can compile the manual with compile.sh (rst2latex required).
* tools/: some tools to work with the files produced by critic2.
* dat/: atomic density and cif database data. These need to be
  accessible to critic2 at runtime (see below).
* examples/: examples showing how to use critic2. See
  examples/examples.txt for more information.

## Compilation and installation

If you downloaded the code from the git repository and not from a
package, you will need to run:

    autoreconf -i

Prepare for compilation by doing:

    ./configure

Use <code>configure --help</code> for information about the
compilation options. The <code>--prefix</code> option sets the
installation path; more details about configure can be found in the
INSTALL file. Once critic2 is configured, compile using:

    make

This should create the critic2 executable inside the src/
subdirectory. The binary can be used directly or the entire critic2
distribution can be installed to the 'prefix' path by doing:

    make install

Critic2 is parallelized for shared-memory architectures (unless
compiled with <code>--disable-openmp</code>). You change the number of
parallel threads by setting the <code>OMP_NUM_THREADS</code>
environment variable. Note that the parallelization flags for
compilers other than ifort and gfortran may not be correct.

In the case of ifort (and maybe other compilers), sometimes it may be
necessary to increase the stack size using, for instance:

export OMP_STACKSIZE=128M

This applies in particular to integrations using YT.

The environment variable CRITIC_HOME is necessary if critic2 was not
installed with 'make install'. It must point to the root directory of
the distribution:

    export CRITIC_HOME=/home/alberto/programs/critic2dir

This variable is necessary for critic2 to find the atomic densities,
the cif dictionary and the library data. These should be in
${CRITIC_HOME}/dat/.

## Which compilers work?

Critic2 uses some features from the more modern Fortran standards,
which may not be available in old compilers. In consequence, not all
compilers may be able to generate the binary and, even if they do, it
may be broken. Two versions of critic2 are distributed. The
**development** version, corresponding to the master branch of the
repository, and the **stable** version, in the stable branch. Only
patches addressing serious bugs will be introduced in the stable
version; all new development happens in the development version.

The stable version is compilable with all versions of gfortran
starting at 4.9. All intel fortran compiler versions from 2011 onwards
also compile the stable code. To download the stable version, click on
the **Branch:** button above and select **stable**.

The development version can be compiled with gfortran-6 and
later. Most other compilers have issues. This is the list of compilers
tested:

* gfortran 4.8: critic2 can not be compiled with this version because
  allocatable components in user-defined types are not supported.
* gfortran 4.9 through 5.4 (and possibly older and newer gfortran-5):
  the code compiles correctly but there are errors allocating and
  deallocating the global field array (sy%f) and other complex
  user-defined types. The program is usable, but problems will arise
  if more than one crystal structure or more than 10 scalar fields are
  loaded.
* gfortran 6.x and gfortran 7.x: no errors.
* ifort 12.1: catastrophic internal compiler error of unknown origin. 
* ifort-14.0.2.144, ifort-15.0.5.233, and ifort-15.2: the compilation
  succeeds, but inexplicable errors happen at runtime when the global
  field array is deallocated in the system_end subroutine. The run may
  also hang if the field array is reallocated (move_alloc
  bug?). Similarly to early versions of gfortran, the program is
  usable, but errors will occur if several crystal structures are
  loaded.
* ifort 16.0.4 and ifort 17.0.1: they gives less problems than earlier
  versions of ifort but occasional errors still occur when loading and
  unloading very many crystal structures in sequence. For ifort
  17.0.1, the trispline interpolation in grids does not work.
* Portland Group Fortran compiler (pgfortran), version 17.3. There are
  two important compiler problems: i) passing subroutines and
  functions whose interface includes multidimensional arrays as
  arguments or function results does not work, and ii) internal
  compiler error when compiling meshmod.f90.

In summary: **Only recent versions of gfortran and intel fortran are
guaranteed to work with the development version. If you can not use
gfortran 6 or newer or ifort 16.x or newer, download the stable
version.** I do not think this is because of errors in the critic2
code (though if you find that it is, please let me know).

If a recent compiler is not available, an alternative is to compile
the program elsewhere with the static linking option:

    LDFLAGS='-static -Wl,--whole-archive -lpthread -Wl,--no-whole-archive' ./configure ...

provided the machine has the same architecture. (The part between the
-Wl is there to prevent statically-linked gfortran executables from
segfaulting.) You can choose the compiler by changing the FC and F77
flags before configure:

    FC=gfortran F77=gfortran ./configure ...

## Compiling and using external libraries

Critic2 can be compiled with [libxc](http://octopus-code.org/wiki/Libxc) and
[libcint](https://github.com/sunqm/libcint) support. Libxc is a
library that implements the calculatio nof exchange-correlation
energies and potentials for a number of different functionals. It is
used in critic2 to calculate exchange and correlation energy densities
via the xc() function in arithmetic expressions. See 'Use of LIBXC in
arithmetic expressions' in the user's guide for instructions on how to
use libxc in critic2. 

To compile critic2 with libxc support, two --with-libxc options must
be passed to configure:

    ./configure --with-libxc-prefix=/opt/libxc --with-libxc-include=/opt/libxc/include

Here the /opt/libxc directory is the target for the libxc installation
(use --prefix=/opt/libxc when you configure libxc). 

libcint is a library for molecular integrals between GTOs. It is used
for testing and in some options to the MOLCALC keyword. To compile
critic2 with libcint support, do either of these two:

    ./configure --with-cint-shared=/opt/libcint/build 
    ./configure --with-cint-static=/opt/libcint/build/

The first will use the libcint.so file in that directory and
dynamically link to it. The libcint.so path needs to be available when
critic2 is executed through the LD_LIBRARY_PATH environment
variable. The second option will include a copy of the static
libcint.a library into the critic2 binary, located in the indicated
path. 

Make sure that you use the same compiler for the libraries and for
critic2; otherwise the compilation will fail.

## Using critic2

The user's guide is in the doc/ directory in plain text format
(user-guide.txt). A copy of the manual in PDF format (user-guide.pdf)
can be generated by running the compile.sh script. This requires a
working LaTeX installation, the rst2latex program (included in the
docutils package), and awk. A concise summary of the syntax can be
found in the syntax.txt file. Several examples are provided in the
examples/ subdirectory.

Critic2 reads a single input file (the cri file). A simple input is:

    crystal cubicBN.cube
    load cubicBN.cube
    yt

which reads the crystal structure from a cube file, then the electron
density from the same cube file, and then calculates the atomic
charges and volumes. Run critic2 as:

    critic2 cubicBN.cri cubicBN.cro

A detailed description of the keywords accepted by critic2 is given in
the user's guide and a short reference in the syntax.txt file. 

## References and citation

The basic references for critic2 are:

* A. Otero-de-la-Roza, E. R. Johnson and V. Luaña, 
  Comput. Phys. Commun. **185**, 1007-1018 (2014)
  (http://dx.doi.org/10.1016/j.cpc.2013.10.026) 
* A. Otero-de-la-Roza, M. A. Blanco, A. Martín Pendás and V. Luaña, 
  Comput. Phys. Commun. **180**, 157–166 (2009)
  (http://dx.doi.org/10.1016/j.cpc.2008.07.018) 

See the outputs and the manual for references pertaining particular keywords. 

## Copyright notice

Copyright (c) 2013-2017 Alberto Otero de la Roza, Ángel Martín Pendás
and Víctor Luaña.

critic2 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

critic2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
