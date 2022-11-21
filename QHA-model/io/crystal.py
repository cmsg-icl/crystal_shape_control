#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Input / output port for CRYSTAL
Dependency: crystal_functions
"""
import constants as cst

__all__ = [
    "read_output",
]

def read_output(output, unit='default',
                read_eigenvector=True, read_symmetry=False, isqha=False):
    """
    """
    
    
    
    
    
class Output_reader:
    """
    
    """
    def __init__(self, output, read_eigenvector, read_symmetry):
        """
        Check if the output specified exists, if it is a frequency output and
        if it is finished. 
        
        The identifier for frequency calculation:
        FORCE CONSTANT MATRIX - NUMERICAL ESTIMATE
        
        The identifier for finished calculation:
        EEEEEEEEEE TERMINATION

        Input:
            output, string, 
        Output:
            -
        """
        import re
        import os

        # File existance. Must be a full name
        if not os.path.isfile(output):
            err_msg = 'Specified file \'' + output + '\' not found.'
            raise FileNotFoundError(err_msg)

        file = open(output_name, 'r', errors='ignore')
        data = file.readlines()
        file.close()
        
        # Normal termination
        is_normal_termination = False
        for idx_ed, line in enumerate(data[::-1]):
            if re.match(
                r'^\s*E+\sTERMINATION', data[idx_line]
            ):
                is_normal_termination = True
                idx_ed = len(data) - 1 - idx_ed
                break
        
        if not is_normal_termination:
            err_msg = 'Specified file \'' + output + '\' is interrupted.'
            raise Exception(err_msg)

        # Frequency file
        is_freq = False
        for idx_bg, line in enumerate(data):
            if re.match(
                r'^\s+FORCE\sCONSTANT\sMATRIX\s-\sNUMERICAL\sESTIMATE',
                data[idx_line]
            ):
                is_freq = True
                break
        
        if not is_freq:
            err_msg = 'Specified file \'' + output + '\' is not a frequency output.'
            raise Exception(err_msg)
        
        # QHA file
        if not isqha:
            self._structure, self._eint, self._nqpoint, self._qpoint, \
            self._nmode, self._frequency, self._symmetry, self._eigenvector \
            = self.auto_read(data, read_eigenvector, read_symmetry)
        else:
            self._structure = []
            self._eint = []
            self._nqpoint = []
            self._qpoint = []
            self._nmode = []
            self._frequency = []
            self._symmetry = []
            self._eigenvector = []
            data_list = self.qha_partition(data)
            for idx_calc, calc in enumerate(data_list):
                self._structure[idx_calc], self._eint[idx_calc], \
                self._nqpoint[idx_calc], self._qpoint[idx_calc], \
                self._nmode[idx_calc], self._frequency[idx_calc], \
                self._symmetry[idx_calc], self._eigenvector[idx_calc] \
                = self.auto_read(calc, read_eigenvector, read_symmetry)

    def auto_read(self, data, read_eigenvector, read_symmetry):
        # Scan the whole file, for only once
        idx_line = 0
        while idx_line < len(data):
            # Get geometry
            if re.match(
                
            ):
                
            # Get internal energy - in this case, DFT total energy
            elif re.match(
                r'^\s*CENTRAL POINT', data[idx_line]
            ):
                idx_line, eint = self.read_eint(data, idx_line)
                continue
            
            # Get Gamma point phonon
            elif re.match(
                
            ):
                
                continue

            # Get phonon dispersion
            elif re.match(
                r'^\s*\*\s*PHONON\sBANDS\s*\*', data[idx_line]
            ):
                idx_line, nqpoint, qpoint, nmode, frequency, symmetry, \
                eigenvector = self.read_dispersion(
                    data, idx_line, read_eigenvector, read_symmetry
                )
                continue
            
            idx_line += 1
            
        return structure, eint, nqpoint, qpoint, nmode, frequency, symmetry, eigenvector
            
    def read_eint(self, data, idx_line):
        """
        Get dft total energy
        """
        eint = float(data[idx_line].strip().split()[2])
        idx_line += 1

        return idx_line, eint
    
    def read_dispersion(self, data, idx_line, read_eigenvector, read_symmetry):
        """
        Get the number of q points and their coordinates
        """
        nqpoint = 0
        qpoint = np.array([], dtype=float)
        frequency = np.array([], dtype=float)
        symmetry = np.array([], dtype=int)
        eigenvector = np.array([], dtype=float)

        idx_new = idx_line + 1
        while idx_new < len(data):
            # Shrink parameters of q point coordinates
            if re.match(
                r'^\s*THE\sPOSITION\sOF\sTHE\sPOINTS\sIS\sEXPRESSED\sIN\sUNITS\s+OF\sDENOMINATOR', 
                data[idx_new]
            ):
                shrink = int(line.strip().split()[-1])
            
            # q point coordinates in fractional coordinates
            elif re.match(
                r'\s*DISPERSION K POINT NUMBER', data[idx_new]
            ):
                coord = np.array(line.strip().split()[7:10], dtype=float)
                qpoint = np.append(qpoint, coord / shrink)
                nqpoint += 1
            
            # read vibration modes at each q point
            elif re.match(
                r'\s*DISPERSION K POINT NUMBER\s*\d', data[idx_new]
            ):
                idx_new += 2
                if re.match(
                    r'\s*MODES\s*EIGV\s*FREQUENCIES\s*IRREP', data[idx_new]
                ):
                    idx_new += 2
                ## phonon frequency and symmetry
                while data[idx_new].strip():
                    line_data = re.findall(
                        r'\-*[\d\.]+[E\d\-\+]*', data[idx_new]
                    )
                    idx_bg = int(line_data[0].strip('-'))
                    idx_ed = int(line_data[1])
                    freq = float(line_data[4])
                    if read_symmetry:
                        symm = int(line_data[4])
                    
                    for idx_m in range(idx_bg, idx_ed + 1):
                        frequency = np.append(frequency, freq)
                        if read_symmetry:
                            symmetry = np.append(symmetry, symm)

                    idx_new += 1
                
                
            
            idx_new += 1
        
        
        qpoint = np.array(self._qpoint)
        frequency = np.array(frequency)
        frequency = np.reshape(frequency, (nqpoint, -1))
        if read_symmetry:
            symmetry = np.reshape(symmetry, (nqpoint, -1))
        