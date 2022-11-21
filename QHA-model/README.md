# Crystal Shape Control project - QHA-model package

This folder contains the ongoing work for developing the simulation package based on exact phonon frequencies. Its temporary name (I haven't got a good name for that), QHA-mode, originates from adopting quasi-harmonic approximation (QHA) for harmonic phonon calculation outputs by [CRYSTAL17](https://www.crystal.unito.it/index.php) and used to be part of [crystal_tools package](https://github.com/crystal-code-tools/crystal_functions). The work of making it independent from crystal_tools is ongoing since now its application scenario has been significantly broadened. For the latest updates please refer to [Spica.Vir.'s fork repository](https://github.com/Spica-Vir/crystal_shape_control/tree/main/QHA-model).

Currently there is no release of this package.

## General Structure
The current development is focused on post-processing of phonon frequencies, so it relies on external solvers to make finite displacements, construct dynamic matrices and print frequencies and eigenvectors of vibration modes. The construction of dynamical matrices and computation of anisotropic pressure is listed as the long-term plan. The following figure shows the utilities of this package. 

![utilities](_fig/utilities.png)

So far outputs of the following code is supported:

* [CRYSTAL17](https://www.crystal.unito.it/index.php)

## Establishing p-V-T relationship
The pressure-volume-temperature (p-V-T) relationship is the foundation of various important thermodynamic properties including entropy, free energy and heat capacity. There are 3 options to establish the p-V-T relationship, as illustrated in the following figure:

![p-V-T](_fig/p-V-T)

1. Purely analytical and EoS based - Inspired by the [qha module of phonopy](https://phonopy.github.io/phonopy/qha.html), minimum computational load.  
2. Derivation based 2 step fittings - Inspired by the QHA module of [CRYSTAL17](https://www.crystal.unito.it/index.php) medium computational load.  
3. Purely numerical minimization - maximum computational load.

## Thermal expansion & coefficients
Equilibrium volume and thermal expansion at finite temperature and pressure are important criteria to examine the reliability of QHA fitting. The following figure shows schemes adopted for thermal expansion and coefficients. 

![expansion](_fig/expansion.png)

Note that the volumetric thermal expansion coefficient $\alpha_{V}(T)$ is computed against the 0K equilibrium volume. Therefore, $V-V_{0}=T\alpha_{V}(T)$.