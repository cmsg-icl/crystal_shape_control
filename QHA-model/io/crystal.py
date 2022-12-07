#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Input / output port for CRYSTAL. All the parameters are returned to consistent
data input formats.
"""
###################### Change this line before release! #######################
import constants as cst
###############################################################################
__all__ = [
    "read_output",
]


def read_output(output, read_eigenvector=True, read_symmetry=False, unit='HARTREE'):
    """
    Read one or multiple output files, return to several nCalc*1 lists of
    following information:

    * Dimensionality
    * Lattice
    * Supercell expansion matrix
    * DFT total energy
    * Number & fractional coordinates of q grid in reciprocal space
    * Number, frequency, symmetry and eigenvectors of phonon modes at q

    All the numbers with units are normalized to the solver unit systems

    Inputs:
        output (string / list)
            Output file name / List of output files
        read_eigenvector (bool)
            Whether to read eigenvectors from file
        read_symmetry (bool)
            Whether to read symmetry of vibrational mode
        unit (string, see constants.py)
            Unit system used in solvers
    Outputs:
        dimension (nCalc*1 list of ints)
            Dimension of each calculation
        structure (nCalc*1 list of pymatgen objects)
            Geometry information of supercells of each calculation
        supercell (nCalc*1 list of 3*3 arrays)
            Supercell expansion matrix of each calculation
        eint (nCalc*1 list of floats)
            DFT total energy of each calculation
        nqpoint (nCalc*1 list of ints)
            Number of q points in reciprocal space of each calculation
        qpoint (nCalc*1 list of nqpoint*3 array)
            Fractional coordinates of q points
        nmode (nCalc*1 list of nqpoint*1 array)
            Number of phonon modes at each q point of each calculation
        frequency (nCalc*1 list of nqpoint*nmode array)
            Frequencies of phonon modes at each q point of each calculation
        symmetry (nCalc*1 list of nqpoint*nmode array)
            Symmetry of phonon modes at each q point of each calculation
        eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
            Normalized eigenvectors of phonon modes at each q point of each
            calculation. Eigenvectors are normalized to 1.
    """
    import traceback
    import numpy as np

    if isinstance(output, str):
        output = [output, ]

    if unit != 'HARTREE':
        global cst
        cst.redefine(unit=unit)

    dimension = []
    structure = []
    supercell = []
    eint = []
    nqpoint = []
    qpoint = []
    nmode = []
    frequency = []
    symmetry = []
    eigenvector = []
    for out in output:
        try:
            out_obj = Output_reader(output=out,
                                    read_eigenvector=read_eigenvector,
                                    read_symmetry=read_symmetry)
        except Exception:
            print('Error occurs! Job terminated.')
            traceback.print_exec()

        # QHA file
        if out_obj.ncalc > 1:
            structure += out_obj.structure[1: out_obj.ncalc + 1]
        else:
            structure += out_obj.structure[0]
        # Supercell may not be defined. If defined, it appears only once
        if out_obj.supercell:
            supercell = [out_obj.supercell[0] for i in range(out_obj.ncalc)]
        else:
            supercell = [np.eye(3) for i in range(out_obj.ncalc)]

        dimension = [out_obj.dimension[0] for i in range(out_obj.ncalc)]
        eint += out_obj.eint
        nqpoint += out_obj.nqpoint
        qpoint += out_obj.qpoint
        nmode += out_obj.nmode
        frequency += out_obj.frequency
        symmetry += out_obj.symmetry
        eigenvector += out_obj.eigenvector

    return dimension, structure, supercell, eint, nqpoint, qpoint, nmode, \
        frequency, symmetry, eigenvector


class Output_reader:
    """
    Class Output_reader opens, reads a single file and returns to the following
    information:

    * Dimensionality
    * Lattice
    * Supercell expansion matrix
    * DFT total energy
    * Number & fractional coordinates of q grid in reciprocal space
    * Number, frequency, symmetry and eigenvectors of phonon modes at q
    """

    def __init__(self, output, read_eigenvector=True, read_symmetry=False):
        """
        Check if the output specified exists, if it is a frequency output and
        if it is finished. 

        The identifier for frequency calculation:
        FORCE CONSTANT MATRIX - NUMERICAL ESTIMATE

        The identifier for finished calculation:
        EEEEEEEEEE TERMINATION

        Input:
            output (string)
                Output file name
            read_eigenvector (bool)
                Whether to read eigenvectors from file
            read_symmetry (bool)
                Whether to read symmetry of vibrational mode
            unit (string, see constants.py)
                Unit system used in solvers
        Output:
            self.ncalc (int)
                Number of calculations
            self.dimension (1*1 list of int)
                Dimension of the computed system. Appears once in all cases.
            self.structure (nCalc*1 list of Pymatgen structures)
                Geometric information of the computed system. Unit: Solver
            self.supercell (1*1 list of 3*3 array)
                Supercell matrix corresponds to SUPERCELL / SCELPHONO. Appears
                once in all cases.
            self.eint (nCalc*1 list of floats)
                Internal energy (DFT total energy). Unit: Solver
            self.nqpoint (nCalc*1 list of ints)
                Number of q points sampled for phonon dispersion
            self.qpoint (nCalc*1 list of nqpoint*3 array)
                Fractional coordinates of sampled q points
            self.nmode (nCalc*1 list of nqpoint*1 array)
                Number of modes at sampled q points
            self.frequency (nCalc*1 list of nqpoint*nmode array)
                Frequencies of phonon modes at sampled q points. Unit: Solver
            self.symmetry (nCalc*1 list of nqpoint*nmode array)
                Symmetry of phonon modes at sampled q points.
            self.eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
                Eigenvectors of phonon modes at sampled q points. Norm of each
                mode is normalized to 1.
        """
        import re
        import os

        # File existance. Must be a full name
        if not os.path.isfile(output):
            err_msg = 'Specified file \'' + output + '\' not found.'
            raise FileNotFoundError(err_msg)

        file = open(output, 'r', errors='ignore')
        data = file.readlines()
        file.close()

        # Initial scan - clean exception messages, check file

        is_normal_termination = False
        is_freq = False
        for idx_line in range(len(data) - 1, -1, -1):
            if re.search(
                r'\s*Note:[\s\S]+exceptions', data[idx_line]
            ):
                del data[idx_line]
                continue

            # Normal termination
            elif re.match(
                r'^\s*E+\sTERMINATION', data[idx_line]
            ):
                is_normal_termination = True
                continue

            # Frequency file
            elif re.match(
                r'^\s+FORCE\sCONSTANT\sMATRIX\s\-\sNUMERICAL\sESTIMATE',
                data[idx_line]
            ):
                is_freq = True
                continue

        if not is_normal_termination:
            err_msg = 'Specified file \'' + output + '\' is interrupted.'
            raise Exception(err_msg)

        if not is_freq:
            err_msg = 'Specified file \'' + output + '\' is not a frequency output.'
            raise Exception(err_msg)

        # Auto-read key data
        self.dimension, self.structure, self.supercell, self.eint, \
            self.nqpoint, self.qpoint, self.nmode, self.frequency, \
            self.symmetry, self.eigenvector = self.auto_read(
                data, read_eigenvector, read_symmetry
            )

        # Clean imaginary modes. Threshold: > 0.00001 THz
        self.clean_imaginary(threshold=-1e-5)
        self.ncalc = len(self.eint)

    def auto_read(self, data, read_eigenvector, read_symmetry):
        """
        Scan the whole file, for only once. Extra 'calc' dimension is for QHA
        files

        Input:
            data (list of string)
                Line-by-line list of the input file
            read_eigenvector (bool)
            read_symmetry (bool)
        Output:
            dimension (1*1 list of int)
            structure (nCalc*1 list of Pymatgen structures)
            supercell (1*1 list of 3*3 array)
            eint (nCalc*1 list of floats)
            nqpoint (nCalc*1 list of ints)
            qpoint (nCalc*1 list of nqpoint*3 array)
            nmode (nCalc*1 list of nqpoint*1 array)
            frequency (nCalc*1 list of nqpoint*nmode array)
            symmetry (nCalc*1 list of nqpoint*nmode array)
            eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
        """
        import re

        idx_line = 0
        dimension = []
        structure = []
        supercell = []
        eint = []
        nqpoint = []
        qpoint = []
        nmode = []
        frequency = []
        symmetry = []
        eigenvector = []
        while idx_line < len(data):
            # Get dimensionality
            if re.match(
                r'^\s+GEOMETRY\sFOR\sWAVE\sFUNCTION\s\-\sDIMENSIONALITY',
                data[idx_line]
            ):
                idx_line, dimen_c = self.read_dimension(data, idx_line)
                dimension.append(dimen_c)

            # Get geometry
            elif re.match(
                r'^\s+DIRECT\sLATTICE\sVECTORS\sCARTESIAN\sCOMPONENTS\s\(ANGSTROM\)',
                data[idx_line]
            ):
                idx_line, struc_c = self.read_structure(
                    data, idx_line, dimen_c)
                structure.append(struc_c)

            # Get supercell expansion matrix
            elif re.match(
                r'^\s+EXPANSION\sMATRIX\sOF\sPRIMITIVE\sCELL',
                data[idx_line]
            ):
                idx_line, scell_c = self.read_supercell(data, idx_line)
                supercell.append(scell_c)

            # Get internal energy - in this case, DFT total energy
            elif re.match(
                r'^\s+CENTRAL POINT',
                data[idx_line]
            ):
                idx_line, eint_c = self.read_eint(data, idx_line)
                eint.append(eint_c)

            # Get Gamma point phonon
            elif re.match(
                r'^\s+MODES\s+EIGV\s+FREQUENCIES\s+IRREP\s+IR\s+INTENS\s+RAMAN',
                data[idx_line]
            ):
                idx_line, nq_c, q_c, nm_c, freq_c, symm_c, eigvt_c \
                    = self.read_gammafreq(
                        data, idx_line, read_eigenvector, read_symmetry
                    )
                nqpoint.append(nq_c)
                qpoint.append(q_c)
                nmode.append(nm_c)
                frequency.append(freq_c)
                symmetry.append(symm_c)
                eigenvector.append(eigvt_c)

            # Get phonon dispersion
            elif re.match(
                r'^\s+\*\s*PHONON\sBANDS\s*\*',
                data[idx_line]
            ):
                idx_line, nq_c, q_c, nm_c, freq_c, symm_c, eigvt_c \
                    = self.read_dispersion(
                        data, idx_line, read_eigenvector, read_symmetry
                    )
                nqpoint.append(nq_c)
                qpoint.append(q_c)
                nmode.append(nm_c)
                frequency.append(freq_c)
                symmetry.append(symm_c)
                eigenvector.append(eigvt_c)

            idx_line += 1

        return dimension, structure, supercell, eint, nqpoint, qpoint, nmode, \
            frequency, symmetry, eigenvector

    def read_dimension(self, data, idx_line):
        """
        Get the dimensionality of the structure

        Input:
            data (list of string)
            idx_line (int)
                Line counter
        Output:
            idx_line (int)
            dimension (int)
        """
        dimension = int(data[idx_line].strip().split()[9])

        return idx_line, dimension

    def read_structure(self, data, idx_line, dimension):
        """
        Get geometries of supercells used for phonon calculation

        Input:
            data (list of string)
            idx_line (int)
            dimension (int)
        Output:
            idx_line (int)
            structure (Pymatgen structure object)
        """
        import re
        import numpy as np
        from pymatgen.core.lattice import Lattice
        from pymatgen.core import Structure

        pbc = {
            1: (True, False, False),
            2: (True, True, False),
            3: (True, True, True)
        }

        idx_line += 2
        vec1 = np.array(data[idx_line].strip().split()[0:3], dtype=float) \
            / cst.ang
        vec2 = np.array(data[idx_line + 1].strip().split()[0:3], dtype=float) \
            / cst.ang
        vec3 = np.array(data[idx_line + 2].strip().split()[0:3], dtype=float) \
            / cst.ang
        latt = Lattice(np.stack([vec1, vec2, vec3]), pbc[dimension])

        idx_line += 9
        atom_species = []
        atom_coords = np.array([], dtype=float)
        while re.match(
            r'^\s+[0-9]+\s+[0-9]+\s+[A-Z]+', data[idx_line]
        ):
            line_info = data[idx_line].strip().split()
            atom_coords = np.append(
                atom_coords, np.array(line_info[3:], dtype=float) / cst.ang
            )
            atom_species.append(line_info[2].capitalize())
            idx_line += 1

        atom_coords = np.reshape(atom_coords, [-1, 3])
        structure = Structure(lattice=latt, species=atom_species,
                              coords=atom_coords, coords_are_cartesian=True)

        return idx_line, structure

    def read_supercell(self, data, idx_line):
        """
        Get supercell expansion matrix used for dispersion calculation

        Input:
            data (list of string)
            idx_line (int)
        Output:
            idx_line (int)
            supercell (3*3 array)
        """
        import numpy as np

        idx_line += 1
        supercell = np.zeros([3, 3])
        for d in range(3):
            supercell[d, :] = np.array(data[idx_line + d].strip().split()[1:],
                                       dtype=float)

        idx_line += 2

        return idx_line, supercell

    def read_eint(self, data, idx_line):
        """
        Get internal energy, in the case of CRYSTAL, DFT total energy

        Input:
            data (list of string)
            idx_line (int)
        Output:
            idx_line (int)
            eint (float)
        """
        eint = float(data[idx_line].strip().split()[2]) / cst.ha

        return idx_line, eint

    def read_gammafreq(self, data, idx_line, read_eigenvector, read_symmetry):
        """
        Get phonons at Gamma point from Gamma point calculation files

        Input:
            data (list of string)
            idx_line (int)
            read_eigenvector (bool)
            read_symmetry (bool)
        Output:
            idx_new (int)
                Same as idx_line
            nqpoint (int)
            qpoint (nqpoint*3 array)
            nmode (nqpoint*1 array)
            frequency (nqpoint*nmode array)
            symmetry (nqpoint*nmode array)
            eigenvector (nqpoint*nmode*natom*3 array)
        """
        import numpy as np
        import math
        import re

        nqpoint = 1
        qpoint = np.array([0., 0., 0.], dtype=float)
        nmode = np.array([], dtype=int)
        frequency = np.array([], dtype=float)
        symmetry = np.array([], dtype=float)
        eigenvector = np.array([], dtype=float)

# temporal
        if read_symmetry:
            raise Exception('Currently not supported')
#####################

        idx_new = idx_line + 2
        # phonon frequency Gamma
        while re.match(
            r'^\s+[0-9]+\-\s+[0-9]+\s+\-*[0-9\.]+E[\-0-9]+',
            data[idx_new]
        ):
            line_data = re.findall(
                r'\-*[0-9\.]+[E\-\+0-9]*',
                data[idx_new]
            )
            idx_bg = int(line_data[0].strip('-'))
            idx_ed = int(line_data[1])
            freq = float(line_data[4]) / cst.thz
            if read_symmetry:
                symm_symbol = re.findall(
                    r'\([A-Z][0-9a-z]*',
                    data[idx_new]
                )[0][1:]
                symm = cst.symmetry_group[symm_symbol]

            for idx_m in range(idx_bg, idx_ed + 1):
                frequency = np.append(frequency, freq)
                if read_symmetry:
                    symmetry = np.append(symmetry, symm)

            idx_new += 1

        nmode = np.append(nmode, len(frequency))
        frequency = np.array([frequency], dtype=float)
        symmetry = np.array([symmetry], dtype=float)

        if read_eigenvector:
            countmode = 0
            natom = int(nmode[0] / 3)
            eigenvector = np.zeros([1, nmode[0], nmode[0]])
            eigvt_save = []
            while countmode < nmode[0]:
                if re.match(
                    r'^\s*FREQ\(CM\*\*\-1\)',
                    data[idx_new]
                ):
                    idx_new += 2
                    # Trim annotation part (12 characters)
                    while re.match(
                        r'^\s+\-*[0-9\.]+',
                        data[idx_new][13:]
                    ):

                        line_eigvt = re.findall(
                            r'\-*[0-9\.]+[E0-9\-\+]*',
                            data[idx_new][13:]
                        )
                        eigvt_save.append(line_eigvt)
                        idx_new += 1

                    countmode += len(line_eigvt)

                idx_new += 1

            nblock = math.floor(nmode[0] / 6)
            idx_m = 0
            for idx_b in range(nblock):
                idx_bg = nmode[0] * idx_b
                idx_ed = nmode[0] * (idx_b + 1)
                m_per_line = 6 - len(eigvt_save[idx_bg]) % 6
                eigenvector[0, :, idx_m:idx_m +
                            m_per_line] = eigvt_save[idx_bg:idx_ed]
                idx_m += m_per_line

            eigenvector = np.transpose(eigenvector, axes=[0, 2, 1])
            eigenvector = np.reshape(eigenvector, [1, nmode[0], natom, 3])
            # Normalize eigenvectors of each mode to 1
            for idx_m in range(nmode[0]):
                eigenvector[0, idx_m] /= np.linalg.norm(eigenvector[0, idx_m])

        return idx_new, nqpoint, qpoint, nmode, frequency, symmetry, eigenvector

    def read_dispersion(self, data, idx_line, read_eigenvector, read_symmetry):
        """
        Get q point coordinates and phonons at each q point from dispersion
        calculation files

        Input:
            data (list of string)
            idx_line (int)
            read_eigenvector (bool)
            read_symmetry (bool)
        Output:
            idx_new (int)
            nqpoint (int)
            qpoint (nqpoint*3 array)
            nmode (nqpoint*1 array)
            frequency (nqpoint*nmode array)
            symmetry (nqpoint*nmode array)
            eigenvector (nqpoint*nmode*natom*3 array)
        """
        import numpy as np
        import math
        import re

        nqpoint = 0
        qpoint = np.array([], dtype=float)
        nmode = np.array([], dtype=int)
        frequency = np.array([], dtype=float)
        symmetry = np.array([], dtype=float)
        eigenvector = []

        idx_new = idx_line + 1
        while idx_new < len(data):
            # Shrink parameters of q point coordinates
            if re.match(
                r'^\s*THE\sPOSITION\sOF\sTHE\sPOINTS\sIS\sEXPRESSED\sIN\sUNITS\s+OF\sDENOMINATOR',
                data[idx_new]
            ):
                shrink = int(data[idx_new].strip().split()[-1])

            # q point coordinates in fractional coordinates
            elif re.match(
                r'\s*DISPERSION\sK\sPOINT\sNUMBER',
                data[idx_new]
            ):
                coord = np.array(data[idx_new].strip().split()[
                                 7:10], dtype=float)
                qpoint = np.append(qpoint, coord / shrink)
                nqpoint += 1
                # read vibration modes at each q point
                idx_new += 2
                if re.match(
                    r'\s*MODES\s*EIGV\s*FREQUENCIES\s*IRREP',
                    data[idx_new]
                ):
                    idx_new += 2
                # phonon frequency and symmetry at q
                mode_at_q = 0
                while re.match(
                    r'^\s+[0-9]+\-\s+[0-9]+\s+\-*[0-9\.]+E[\-0-9]+',
                    data[idx_new]
                ):
                    line_data = re.findall(
                        r'\-*[0-9\.]+[E0-9\-\+]*',
                        data[idx_new]
                    )
                    idx_bg = int(line_data[0].strip('-'))
                    idx_ed = int(line_data[1])
                    freq = float(line_data[4]) / cst.thz
                    if read_symmetry:
                        symm = int(line_data[5])

                    for idx_m in range(idx_bg, idx_ed + 1):
                        mode_at_q += 1
                        frequency = np.append(frequency, freq)
                        if read_symmetry:
                            symmetry = np.append(symmetry, symm)

                    idx_new += 1

                nmode = np.append(nmode, mode_at_q)
                # eigenvector at q
                if read_eigenvector:
                    countmode = 0
                    while countmode < mode_at_q:
                        eigvt_at_q = []
                        if re.match(
                            r'\s*FREQ\(CM\*\*\-1\)',
                            data[idx_new]
                        ):
                            idx_new += 2
                            # Trim annotation part (12 characters)
                            while re.match(
                                r'^\s+\-*[0-9\.]+',
                                data[idx_new][13:]
                            ):
                                line_eigvt = re.findall(
                                    r'\-*[0-9\.]+[E0-9\-\+]*',
                                    data[idx_new][13:]
                                )
                                eigvt_at_q.append(line_eigvt)
                                idx_new += 1

                            countmode += len(line_eigvt)

                        idx_new += 1

                    natom = int(mode_at_q / 3)
                    eigvt_save = np.zeros([mode_at_q, mode_at_q])
                    nblock = math.floor(mode_at_q / 6)
                    idx_m = 0
                    for idx_b in range(nblock):
                        idx_bg = mode_at_q * idx_b
                        idx_ed = mode_at_q * (idx_b + 1)
                        m_per_line = 6 - len(eigvt_at_q[idx_bg]) % 6
                        eigvt_save[:, idx_m:idx_m +
                                   m_per_line] = eigvt_at_q[idx_bg:idx_ed]
                        idx_m += m_per_line

                    eigvt_save = np.transpose(eigvt_save, axes=[1, 0])
                    eigvt_save = np.reshape(eigvt_save, [mode_at_q, natom, 3])
                    # Normalize eigenvectors of each mode to 1
                    for idx_m in range(mode_at_q):
                        eigvt_save[idx_m] /= np.linalg.norm(eigvt_save[idx_m])

                    eigenvector.append(eigvt_save)

            idx_new += 1

        nqpoint = int(nqpoint)
        qpoint = np.reshape(qpoint, [nqpoint, -1])
        frequency = np.reshape(frequency, [nqpoint, -1])
        if read_symmetry:
            symmetry = np.reshape(symmetry, [nqpoint, -1])

        eigenvector = np.array(eigenvector)

        return idx_new, nqpoint, qpoint, nmode, frequency, symmetry, eigenvector

    def clean_imaginary(self, threshold):
        """
        Clean imaginary modes, or any mode with frequency lower than threshold,
        and corresponding eigenvectors with numpy NaN format and raise warning.

        Input:
            threshold (float)
                Threshold of frequencies. Unit: THz
        Output:
            self.nmode (nCalc*1 list of nqpoint*1 array)
            self.frequency (nCalc*1 list of nqpoint*nmode array)
            self.symmetry (nCalc*1 list of nqpoint*nmode array)
            self.eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
        """
        import numpy as np
        import warnings

        threshold /= cst.thz
        ncalc = len(self.nmode)

        for idx_c in range(ncalc):
            if np.all(self.frequency[idx_c] >= threshold):
                continue

            warnings.warn('Imaginary mode detected. Frequency, symmetry and eigenvector aresubstituted by numpy.nan.',
                          stacklevel=2)
            idx_img = np.where(self.frequency[idx_c] < threshold)
            self.frequency[idx_c][idx_img] = np.nan
            if self.symmetry[idx_c].size:
                self.symmetry[idx_c][idx_img] = np.nan
            if self.eigenvector[idx_c].size:
                self.eigenvector[idx_c][idx_img] = np.nan

        return self
