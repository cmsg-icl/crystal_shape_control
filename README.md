# Crystal Shape Control project

The repository for Imperial-BASF research project on multi-scale modelling of molecular crystals. 

## Topics:
* Ab initio and quasi-harmonic method for thermodynamics of molecular crystals
* Dispersion and BSSE corrected DFT energy for molecular crystals
* Interfacial therodynamics and crystal growth

## Software:
Current focus:

* [CRYSTAL](https://www.crystal.unito.it/): A Gaussian orbital periodic DFT code.  
* [Quantum Espresso](https://www.quantum-espresso.org/): A planar wave periodic DFT code.  
* [GULP](http://gulp.curtin.edu.au/gulp/) : A classical force field for LD (analytical) and MD (numerical).  

Supported:

* [ONETEP](https://onetep.org/): A linear-scaling periodic DFT code based on generalized orthogonal Wannier function orbitals.
* [LAMMPS](https://www.lammps.org/): A classical force field MD solver for large systems.
* [GROMACS](https://www.gromacs.org/): A composite MD simulation package.  

## Table of contents
  
1. **QHA-model**, Python 3 scripts for quasi-harmonic fittings based on exact phonon frequencies. **N.B.** Its precursor is thermodynamics script implemented in [CRYSTALpytools](https://github.com/crystal-code-tools/CRYSTALpytools) package, and it is now used for testing ideas. *Spica. Vir.*  
2. **ONETEP_conv_test**, ONETEP convergence testing scripts in bash. See [README](https://github.com/cmsg-icl/crystal_shape_control/tree/main/ONETEP_conv_test) for details. *Spica. Vir.*  
3. **Dimer-disp.ipynb**, a python3 script displacing a molecule in dimer along any vector. Geometry read from CRYSTAL output. [CRYSTALpytools](https://github.com/crystal-code-tools/CRYSTALpytools) package required. *Spica. Vir.*  
4. **Surface-Cut**, a 'semi-atomic' scheme based on python3 script stacking 2D periodic molecular layers to generate twisted slab surfaces for molecular crystals. *Spica. Vir.*
5. **qe2cif.py**, Read Quantum-Espresso pw.x output file and generate cif geometry. *Spica. Vir.*
6. **xsf-kit**, Read [XCrySDen](http://www.xcrysden.org/) real space 3D grid data in [xsf format](http://www.xcrysden.org/doc/XSF.html) and perform planar-averaged 1D profile analysis along 3 lattice vectors / get 3D differential data / get planar-averaged 1D differential profile. Also as a practice of free format Fortran. See the comment lins of 'main.f' for instructions. *Spica. Vir.*

## Student
**H. Zhou** 21 PhD, Dept. Chem., GitHub: [Spica-Vir](https://github.com/Spica-Vir)  

## Post Studnets
**A. Arber** 21 IMSE MRes  
**K. Tallat-Kelpsa** 21 IMSE MRes
