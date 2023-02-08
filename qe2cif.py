#!/bin/env python
"""
Transform geometry from Quantum Espresso pw.x output into a CIF file for 
visuallisation and further format translations. 

By Spical. Vir., ICL, spica.h.zhou@gmail.com
12:01:50, Feb.02, 23
"""
import sys
import re
import numpy as np
from pymatgen.core.structure import Structure
from pymatgen.io.cif import CifWriter

def read_qe_output(qe_file):
    """
    Read Quantum Espresso pw.x output file
    """
    file = open(qe_file, 'r', errors='ignore')
    data = file.readlines()
    file.close()
    
    for i, line in enumerate(data):
        if re.match(r'^\s+Crystallographic axes', line):
            atom_bg_line = i + 3
            is_cart = False
            continue
        elif re.match(r'^\s+Cartesian axes', line):
            atom_bg_line = i + 3
            is_cart = True
            continue
        elif re.match(r'^\s+number of k points=', line):
            atom_ed_line = i - 1
            continue
        elif re.match(r'^\s+lattice parameter \(alat\)  =', line):
            alat = float(line.strip().split()[4]) * 0.529177210903
            continue
        elif re.match(r'^\s+crystal axes\: \(cart\. coord\. in units of alat\)', line):
            latt_bg_line = i + 1
            continue
        elif re.match(r'^\s+reciprocal axes\: \(cart\. coord\. in units', line):
            latt_ed_line = i - 1
            continue
        else:
            continue
    
    atom_spec = [l.strip().split()[1] for l in data[atom_bg_line : atom_ed_line]]
    atom_cord = [l.strip().split()[6:9] for l in data[atom_bg_line : atom_ed_line]]
    atom_cord = np.array(atom_cord, dtype=float)
    if is_cart:
        atom_cord *= alat
    
    latt = [l.strip().split()[3:6] for l in data[latt_bg_line : latt_ed_line]]
    latt = np.array(latt, dtype=float) * alat
    
    return latt, atom_spec, atom_cord, is_cart


qe_file = sys.argv[1]
lattice, species, coords, is_cart = read_qe_output(qe_file)
pmg_struc = Structure(lattice=lattice, species=species, coords=coords, coords_are_cartesian=is_cart)
CifWriter(pmg_struc, symprec=True).write_file(sys.argv[2])

