# Crystal Shape Control project - QHA-fit package

This folder contains unfinished work for developing Quasi-Harmonic Approximation (QHA) fitting package for harmonic phonon calculation outputs by [CRYSTAL17](https://www.crystal.unito.it/index.php).

Merged to main branch in advance due to the change in developing. Contents included in this package are used for developing the phonon submodule of [crystal_tools package](https://github.com/crystal-code-tools/crystal_functions), and for the latest updates please refer to [Spica.Vir.'s fork repository](https://github.com/Spica-Vir/crystal_shape_control).

## Table of contents

`ha-energy.ipynb` - Calculate the harmonic Helmholtz free energy at any given temperature range based on CRYSTAL17 harmonic phonon '.out' file.

`qha-fit.ipynb` - Fit the thermal expansions of independent lattice parameters by minimizing the 2nd-order Taylor expansion of Helmholtz free energy.

`visualise.ipynb` - Post-processing of QHA fitting. Visualize the thermal expansion curves of independent lattice parameters and volumes. Visualize the Helmholtz free energy - Temperature curve. Rearrange the outputs of `qha-fit.ipynb`. Examine the eigenvalues of fitted Hessian matrices of free energy and visualize the distribution of negative eigenvalues.

`qha-freq.ipynb` - Fit the frequencies of vibrational modes as the function of volume. Unfinished. Finished part: A generally applicable class to process and extra critical data from harmonic phonon calculation. A class to rearrange data by modes. A class to fit harmonic frequency as the polynomial function of volume.
