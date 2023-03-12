#!/usr/bin/env python3
# -*- coding: utf-8 -*-
###################### Change this line before release! #######################
import constants as cst
###############################################################################
global cst

# __all__ = [
#     "read_output",
# ]


def read_output(output, read_eigenvector=True):
    """
    """
    import traceback
    import numpy as np

    if isinstance(output, str):
        output = [output, ]

    ncalc = 0
    dimension = []
    structure = []
    supercell = []
    nqpoint = []
    qpoint = []
    eint = []
    nmode = []
    frequency = []
    symmetry = []
    eigenvector = []
    for out in output:
        try:
            out_obj = Output_reader()
            in_config, out_config = out_obj.initial_scan(output=out,
                                                         read_eigenvector=read_eigenvector)
        except Exception:
            print('Error occurs during reading inputs! Job terminated.')
            traceback.print_exec()
        # Read outputs
        ncalc += len(in_config) - 1
        for idx in range(ncalc):
            result_i = out_obj.read_input(in_config[idx], in_config[idx + 1])
            dimension.append(result_i[0])
            structure.append(result_i[1])
            supercell.append(result_i[2])
            nqpoint.append(result_i[3])
            qpoint.append(result_i[4])

            result_o = out_obj.read_output(out_config[idx], out_config[idx + 1],
                                           structure[idx], nqpoint[idx],
                                           read_eigenvector=read_eigenvector)

            eint.append(result_o[0])
            del structure[-1]  # For structural optimisation
            structure.append(result_o[1])
            nmode.append(result_o[2])
            frequency.append(result_o[3])
            eigenvector.append(result_o[4])

    return ncalc, dimension, structure, supercell, eint, nqpoint, qpoint, \
        nmode, frequency, symmetry, eigenvector


class Output_reader:
    """
    Class Output_reader opens, reads a single file and returns to the following
    information:

    * Dimensionality
    * Lattice
    * Supercell expansion matrix
    * Total energy
    * Number, fractional coordinates and weight of q grid in reciprocal space
    * Number, frequency, symmetry and eigenvectors of phonon modes at q
    """

    def __init__(self):
        pass

    def initial_scan(self, output, read_eigenvector):
        """
        Check if the output exists, if it is a phonon output and if it is
        finished.

        The identifier for phonon output:
        *  phonon       -

        The identifier for eigencectors output:
        *  eigenvectors -

        The identifier for normal termination:
          Job Finished at

        Input:
            output (string)
                Output file name
            read_eigenvector (bool)
                Whether to read eigenvectors from file
        Output:

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
            self.eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
                Eigenvectors of phonon modes at sampled q points. Norm of each
                mode is normalized to 1.
        """
        import re
        import os
        import warnings

        # File existance. Must be a full name
        if not os.path.isfile(output):
            err_msg = 'Specified file \'' + output + '\' not found.'
            raise FileNotFoundError(err_msg)

        file = open(output, 'r', errors='ignore')
        self.data = file.readlines()
        file.close()

        # Initial scan - clean exception messages, check file, divide file by configurations

        is_normal_termination = False
        is_freq = False
        is_eigvt = False
        in_config = []
        out_config = []
        for idx_line, line in enumerate(self.data[::-1]):
            if re.search(r'\s*Note:[\s\S]+exceptions', line):
                del data[idx_line]
                continue
            # Normal termination
            elif re.match(r'^\s+Job Finished at', line):
                is_normal_termination = True
                continue
            # Phonon option activated
            elif re.match(r'^\*\s+phonon\s+\-', line):
                is_freq = True
                continue
            # (Optional) Eigenvector option activated
            elif re.match(r'^\*\s+eigenvectors\s+\-', line):
                is_eigvt = True
                continue
            # divide file by configurations
            elif re.match(r'^\*\s+Input for [Cc]onfiguration', line):
                in_config.append(len(self.data) - idx_line - 1)
                continue
            elif re.match(r'^\*\s+General input information', line):
                in_config.append(len(self.data) - idx_line - 1)
                continue
            elif re.match(r'^\*\s+Output for [Cc]onfiguration', line):
                out_config.append(len(self.data) - idx_line - 1)
                continue
            else:
                continue

        if not is_normal_termination:
            err_msg = 'Specified file \'' + output + '\' is interrupted.'
            raise Exception(err_msg)

        if not is_freq:
            err_msg = 'Specified file \'' + output + '\' is not a frequency output.'
            raise Exception(err_msg)

        if read_eigenvector and not is_eigvt:
            warnings.warn(
                "GULP option 'eigenvectors' not found. 'read_eigenvector' is set to 'False'.", stacklevel=2)

        in_config.reverse()
        out_config.reverse()
        out_config.append(len(self.data) - 1)

        return in_config, out_config

    def read_input(self, bg_line, ed_line):
        """
        Scan the input summary region for information

        Input:
            bg_line (int)
            ed_line (int)
        Output:
            dimension (int)
            structure (Pymatgen structure) Unit: Solver
            supercell (3*3 array)
            nqpoint (int)
            qpoint (nqpoint*4 array - [frac_x, frac_y, frac_z, weight])
        """
        import re
        import numpy as np
        from pymatgen.core import IStructure

        supercell = np.eye(3)
        idx_line = bg_line
        while idx_line < ed_line:
            line = self.data[idx_line]
            # Get dimensionality
            if re.match(r'^\s+Dimensionality = ', line):
                dimension = int(line.strip().split()[2])
                idx_line += 1
                continue
            # Get supercell expansion matrix
            elif re.match(r'^\s+Supercell dimensions :', line):
                info = line.strip().split()
                idx_line += 1
                # info[5] - x; info[8] - y; info[11] - z
                for i in range(dimension):
                    supercell[i, i] = info[int(5 + 3 * i)]
                continue
            # Get space group
            elif re.match(r'^\s+Patterson group', line):
                group = ''
                for txt in line.strip().split()[3:]:
                    group += txt
                idx_line += 1
                continue
            # Get lattice matrix
            elif re.match(r'^\s+Cartesian lattice vectors', line):
                idx_line, cell = self.read_lattice(idx_line, dimension)
                continue
            # Get atomic coordinates
            elif re.match(r'^\s+Fractional coordinates of asymmetric', line):
                idx_line, atom = self.read_atom(idx_line)
                continue
            # Get q point
            elif re.match(r'^\s+Brillouin zone sampling points :', line):
                idx_line, nqpoint, qpoint = self.read_qpoint(idx_line)
                continue
            else:
                idx_line += 1

        structure = IStructure.from_spacegroup(sg=group, lattice=cell,
                                               species=atom[0], coords=atom[1])

        return dimension, structure, supercell, nqpoint, qpoint

    def read_output(self, bg_line, ed_line, init_geom, nqpoint, read_eigenvector):
        """
        Scan the output summary region for information

        Input:
            bg_line (int)
            ed_line (int)
            init_geom (PyMatGen Structure)
            nqpoint (int)
            read_eigenvector (bool)
        Output:
            lattice (Optional, Pymatgen lattice)
            eint (float)
            nmode (nqpoint*1 array)
            frequency (nqpoint*nmode[q] array)
            eigenvector (nqpoint*nmode*natom*3 complex array)
        """
        import re
        import numpy as np
        from pymatgen.core import IStructure

        # Scan over the file
        idx_line = bg_line
        while idx_line < ed_line:
            line = self.data[idx_line]
            # Get internal energy
            if re.match(r'^\s+Total lattice energy\s+=[\s\S]+eV', line):
                eint = float(line.strip().split()[4]) / cst.ev
                idx_line += 1
                continue
            # Get potentially existing optimised structures
            elif re.match('r^\s+Final asymmetric unit', line):
                idx_line, atom = self.read_atom(idx_line)
                continue
            elif re.match('r^\s+Final Cartesian lattice', line):
                idx_line, cell = self.read_lattice(idx_line, dimension)
                continue
            # Get phonons
            elif re.match(r'^\s+K point\s+[0-9]+\s=[\s\.\-0-9]+Weight\s=', line):
                idx_line, nmode, frequency, eigenvector = \
                    self.read_phonon(idx_line, nqpoint, read_eigenvector)
                continue

            idx_line += 1

        # Clean imaginary modes. Threshold: > 0.01 cm^-1
        frequency, eigenvector = self.clean_imaginary(
            frequency, eigenvector, threshold=-1e-2)

        # Update geometry
        group = init_geom.get_space_group_info()[1]
        if 'atom' in vars() and 'cell' in vars():  # Full opt
            structure = IStructure().from_spacegroup(sg=group,
                                                     lattice=cell,
                                                     species=atom[0],
                                                     coords=atom[1])
        elif 'atom' in vars() and 'cell' not in vars():  # Atomic coords opt
            structure = IStructure().from_spacegroup(sg=group,
                                                     lattice=init_geom.lattice,
                                                     species=atom[0],
                                                     coords=atom[1])
        elif 'atom' not in vars() and 'cell' in vars():  # Cell opt
            structure = IStructure().from_spacegroup(sg=group,
                                                     lattice=cell,
                                                     species=init_geom.species,
                                                     coords=[[s.x, s.y, s.z] for s in init_geom.sites])
        else:  # No opt
            structure = init_geom

        return eint, structure, nmode, frequency, eigenvector

    def read_lattice(self, idx_line, dimension):
        """
        Get lattice matrix

        Input:
            idx_line (int)
            dimension (int)
        Output:
            idx_line (int)
            cell (Pymatgen Lattice)
        """
        import numpy as np
        from pymatgen.core.lattice import Lattice

        vecs = np.zeros([3, 3], dtype=float)
        pbc = {
            1: (True, False, False),
            2: (True, True, False),
            3: (True, True, True)
        }

        idx_line += 2
        vecs[0, :] = self.data[idx_line].strip().split()[0:3]
        idx_line += 1
        vecs[1, :] = self.data[idx_line].strip().split()[0:3]
        idx_line += 1
        vecs[2, :] = self.data[idx_line].strip().split()[0:3]
        cell = Lattice(vecs / cst.ang, pbc[dimension])

        return idx_line, cell

    def read_atom(self, idx_line):
        """
        Get label and internal coordinates of atoms

        Input:
            idx_line (int)
        Output:
            idx_line (int)
            atom (2*1 list)
        """
        import re
        import numpy as np

        idx_line += 6
        coord = []
        species = []
        while not re.match(r'^\-+', self.data[idx_line]):
            line = re.split('[\s\*]+', self.data[idx_line].strip())
            coord.append(line[3:6])
            species.append(re.match(r'^[A-Za-z]+', line[1]).group(0))
            idx_line += 1

        coord = np.array(coord, dtype=float)
        atom = [species, coord]

        return idx_line, atom

    def read_qpoint(self, idx_line):
        """
        Get the number, fractional coordinate and weight of sampling q points 

        Input:
            idx_line (int)
        Output:
            idx_line (int)
            nqpoint (int)
            qpoint (nqpoint*4 array)
        """
        import re
        import numpy as np

        idx_line += 5
        qpoint = []
        while not re.match(r'^\-+', self.data[idx_line]):
            qpoint.append(self.data[idx_line].strip().split()[1:])
            idx_line += 1

        qpoint = np.array(qpoint, dtype=float)
        nqpoint = np.shape(qpoint)[0]

        return idx_line, nqpoint, qpoint

    def read_phonon(self, idx_line, nqpoint, read_eigenvector):
        """
        Get the number, frequency and eigenvectors of phonons at each q point.

        N.B. Currently eigenvector should be mass-unweighted and unphased. In
        GULP 6.1.2 and beyond, this is enabled by 'eigenvector' keyword and 
        'eigvector_type mass-unweighted' option. Other options, or GULP earlier
        than 6.1.2, are not supported.

        Input:
            idx_line (int)
            nqpoint (int)
            read_eigenvector (bool)
        Output:
            idx_line (int)
            nmode (nqpoint*1 array)
            frequency (nqpoint*nmode array)
            eigenvector (nqpoint*nmode*natom*3 array)
        """
        import re
        import numpy as np

        idx_q = 0
        nmode = np.zeros(nqpoint, dtype=int)
        frequency = [[] for i in range(nqpoint)]
        eigenvector = [[] for i in range(nqpoint)]
        freq_q = []
        eigvt_q = []
        while idx_q < nqpoint:
            idx_line += 1
            line = self.data[idx_line]
            # Keyword 'phonon' only
            if re.match(r'^\s+[0-9\-]+\.[0-9]{2}', line):
                freq_q += line.strip().split()
            # Keyword 'phonon' + 'eigenvector'
            elif re.match(r'^\s+Frequency\s+[0-9\.\-]+', line):
                freq_q += line.strip().split()[1:]
            # Read eigenvector
            elif read_eigenvector and re.match(r'^\s+[0-9]+\s[xyz]\s+[0-9\-\.]+', line):
                info = line.strip().split()
                if len(info) == 5:  # Real eigenvectors
                    eigvt_q.append([float(info[2])+0.j,
                                    float(info[3])+0.j,
                                    float(info[4])+0.j, ])
                elif len(info) == 8:  # Complex eigenvectors
                    eigvt_q.append([float(info[2])+float(info[3])*1j,
                                    float(info[4])+float(info[5])*1j,
                                    float(info[6])+float(info[7])*1j])
            # Store data from the finished q point
            elif re.match(r'^\s+K point\s+[0-9]+\s=[\s\.\-0-9]+Weight\s=', line) \
                    or re.match(r'^\s+Phonon properties', line):
                frequency[idx_q] = np.array(freq_q, dtype=float)
                nmode[idx_q] = len(frequency[idx_q])
                freq_q = []
                if read_eigenvector:
                    nmd = len(frequency[idx_q])
                    nat = int(len(frequency[idx_q]) / 3)
                    eigenvector[idx_q] = np.zeros([nmd, nat, 3], dtype=complex)
                    eigvt_q = np.array(eigvt_q, dtype=complex)
                    # Reshape eigenvector
                    for idx_l, l in enumerate(eigvt_q):
                        for idx_n, n in enumerate(l):
                            idx_f = (idx_l // nmd) * 3 + idx_n
                            idx_a = (idx_l % nmd) // 3
                            idx_c = (idx_l % nmd) % 3
                            eigenvector[idx_q][idx_f, idx_a, idx_c] = n

                    eigvt_q = []

                idx_q += 1
            else:
                continue
        frequency = np.array(frequency, dtype=float) / cst.cm_1
        eigenvector = np.array(eigenvector, dtype=complex)
        # Normalize eigenvectors of each mode to 1
        if read_eigenvector:
            for idx_q, eigv_q in enumerate(eigenvector):
                for idx_m, eigv_m in enumerate(eigv_q):
                    eigenvector[idx_q, idx_m] /= np.linalg.norm(eigv_m)

        return idx_line, nmode, frequency, eigenvector

    @staticmethod
    def clean_imaginary(frequency, eigenvector, threshold):
        """
        Clean imaginary modes, or any mode with frequency lower than threshold,
        and corresponding eigenvectors with numpy NaN format and raise warning.

        Input:
            frequency (nqpoint*nmode array)
            eigenvector (nqpoint*nmode*natom*3 array)
            threshold (float)
                Threshold of frequencies. Unit: cm^-1
        Output:
            frequency (nCalc*1 list of nqpoint*nmode array)
            eigenvector (nCalc*1 list of nqpoint*nmode*natom*3 array)
        """
        import numpy as np
        import warnings

        threshold /= cst.cm_1
        nqpoint = np.shape(frequency)[0]

        for idx_q in range(nqpoint):
            if np.all(frequency[idx_q] >= threshold):
                continue

            warnings.warn('Imaginary mode detected. Frequency and eigenvector are substituted by numpy.nan.',
                          stacklevel=2)
            idx_img = np.where(frequency[idx_q] < threshold)
            frequency[idx_q][idx_img] = np.nan
            if eigenvector[idx_q].size:
                eigenvector[idx_q][idx_img] = np.nan

        return frequency, eigenvector
