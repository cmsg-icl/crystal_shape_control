# Crystal Shape Control project

The repository for Imperial-BASF research project on multi-scale modelling of molecular crystals. 

## Topics:
* Ab initio thermodynamics of molecular crystals
* Dispersion and BSSE corrected DFT energy for molecular crystals
* Interfacial therodynamics based on classica force field

## Software:
Current focus:

* [CRYSTAL17](https://www.crystal.unito.it/index.php): A Gaussian orbital periodic DFT code.  
* [ONETEP](https://onetep.org/): A linear-scaling periodic DFT code based on generalized orthogonal Wannier function orbitals.  
* [LAMMPS](https://www.lammps.org/): A classical force field MD solver for large systems.  
* [GULP](http://gulp.curtin.edu.au/gulp/) : A classical force field for LD (analytical) and MD (numerical).  

Supported:

* [Moltemplate](http://moltemplate.org/): A geometry modeller for LAMMPS.  
* [GROMACS](https://www.gromacs.org/): A composite MD simulation package.  

## Table of contents

1. **Job_Submitter_general_IC-CX1**, A general job submission script in bash for CX1, with configured files. For details please see the [manual](Job_Submitter_general_IC-CX1/README.md). *Spica. Vir. based on scripts by Dr G. Mallia*  
2. **Job_Submitter**, Machine and code specific job submission scripts in bash. Typically it allows more flexibility in terms of usage than the general one. *Spica. Vir. based on scripts by Dr G. Mallia*  
3. **QHA-fit**, Python 3 scripts for quasi-harmonic fittings of CRYSTAL outputs. **N.B.** The current files are used only for backup. QHA post-processing implemented in [crystal_functions](https://github.com/crystal-code-tools/crystal_functions) package is under developing. *Spica. Vir.*  
4. **conv_test**, ONETEP convergence testing scripts in bash. See [README](conv_test/README.md) for details. *Spica. Vir.*  
5. **Dimer-disp.ipynb**, a python3 script displacing a molecule in dimer along any vector. Geometry read from CRYSTAL output. [crystal_functions](https://github.com/crystal-code-tools/crystal_functions) package required. *Spica. Vir.*  

## Students:
**H. Zhou** 21 PhD, Dept. Chem., GitHub: [Spica-Vir](https://github.com/Spica-Vir)  
**A. Arber** 21 IMSE MRes  
**K. Tallat-Kelpsa** 21 IMSE MRes
