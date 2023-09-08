#!/bin/env python
"""
Inter-transform geometry between Quantum Espresso pw.x output and a CIF file 
for visuallisation and further format translations. 

By Spical. Vir., ICL, spica.h.zhou@gmail.com
12:01:50, Feb.02, 23
"""


def read_qe_output(qe_file):
    """
    Read Quantum Espresso pw.x output file
    """
    import re
    import numpy as np

    file = open(qe_file, 'r', errors='ignore')
    data = file.readlines()
    file.close()

    strip_latt = False
    for i, line in enumerate(data):
        if re.match(r'^\s*CELL_PARAMETERS \(alat=', line):
            alat = float(line.strip().split()[2][:-1]) * 0.529177210903
            latt_bg_line = i + 1
            latt_ed_line = i + 4
            strip_latt = False
        elif re.match(r'^\s+lattice parameter \(alat\)', line):
            alat = float(line.strip().split()[4]) * 0.529177210903
        elif re.match(r'^\s+crystal axes\: \(cart\. coord\.', line):
            latt_bg_line = i + 1
            latt_ed_line = i + 4
            strip_latt = True
        elif re.match(r'^\s*ATOMIC_POSITIONS', line):
            atom_bg_line = i + 1
            if 'angstrom' in line:
                is_cart = True
            else:
                is_cart = False

        elif re.match(r'^\s*Writing config-only to output data dir', line):
            atom_ed_line = i - 3
        elif re.match(r'^\s*End final coordinates', line):
            atom_ed_line = i
            break
        else:
            continue

    atom_spec = []
    atom_cord = []
    atom_rstct = []
    for l in data[atom_bg_line:atom_ed_line]:
        l_data = l.strip().split()
        atom_spec.append(l_data[0])
        atom_cord.append(l_data[1:4])
        if len(l_data) > 4:
            string = ''.join(' ' + i for i in l_data[4:])
            string = ' ' + string
        else:
            string = ''
        atom_rstct.append(string)

    atom_cord = np.array(atom_cord, dtype=float)

    if strip_latt:
        latt = [l.strip().split()[3:6] for l in data[latt_bg_line: latt_ed_line]]
    else:
        latt = [l.strip().split() for l in data[latt_bg_line: latt_ed_line]]
    latt = np.array(latt, dtype=float) * alat

    return latt, atom_spec, atom_cord, atom_rstct, is_cart


def lattice_transfer(latt, atom_spec, atom_cord, is_cart):
    """
    Interpreting the data from QE output to input
    """
    from pymatgen.core.lattice import Lattice
    from pymatgen.core.structure import Structure
    import numpy as np

    box = Lattice(latt)
    celldms = np.array([box.a / 0.529177210903,
                        box.b / box.a,
                        box.c / box.a,
                        np.cos(box.alpha / 180 * np.pi),
                        np.cos(box.beta / 180 * np.pi),
                        np.cos(box.gamma / 180 * np.pi)], dtype=float)
    struc = Structure(box, atom_spec, atom_cord, coords_are_cartesian=is_cart)

    return celldms, latt, struc


qe_file = input('Enter the Quantum Espresso pw.x output file: ')
nformula = input('Number of formulas per cell: ')

latt, atom_spec, atom_cord, atom_rstct, is_cart = read_qe_output(qe_file)
celldms, latt, struc = lattice_transfer(latt, atom_spec, atom_cord, is_cart)

print('Cell dimensions: ')
print('celldm(1) = %12.6f' % celldms[0])
print('celldm(2) = %12.6f' % celldms[1])
print('celldm(3) = %12.6f' % celldms[2])
print('celldm(4) = %12.6f' % celldms[3])
print('celldm(5) = %12.6f' % celldms[4])
print('celldm(6) = %12.6f' % celldms[5])
print('\n')
print('CELL_PARAMETERS {angstrom}')
print('%16.8f%16.8f%16.8f' % (latt[0, 0], latt[0, 1], latt[0, 2]))
print('%16.8f%16.8f%16.8f' % (latt[1, 0], latt[1, 1], latt[1, 2]))
print('%16.8f%16.8f%16.8f' % (latt[2, 0], latt[2, 1], latt[2, 2]))
print('\n')
print('Atomic coordinates (fractional): ')
for idx, atom in enumerate(struc.frac_coords):
    if idx % int(nformula) == 0:
        print('%3s%12f%12f%12f%s' %
              (struc.species[idx], atom[0], atom[1], atom[2], atom_rstct[idx]))
    else:
        continue
print('\n')
print('Atomic coordinates (Cartesian): ')
for idx, atom in enumerate(struc.cart_coords):
    if idx % int(nformula) == 0:
        print('%3s%12f%12f%12f%s' %
              (struc.species[idx], atom[0], atom[1], atom[2], atom_rstct[idx]))
    else:
        continue
