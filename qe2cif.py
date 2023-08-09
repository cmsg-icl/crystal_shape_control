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

    atom_block_flag = False
    for i, line in enumerate(data):
        if re.match(r'^\s+Crystallographic axes', line):
            atom_bg_line = i + 3
            is_cart = False
            atom_block_flag = True
            continue
        elif re.match(r'^\s+site n\.\s+atom\s+positions \(alat units\)', line):
            atom_bg_line = i + 1
            is_cart = True
            atom_block_flag = True
            continue
        elif atom_block_flag and len(line.strip()) == 0:
            atom_ed_line = i
            atom_block_flag = False
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

    if 'is_cart' not in locals().keys():
        raise Exception('Atomic coord. block not identified')
    if 'latt_bg_line' not in locals().keys():
        raise Exception('Latt. block not identified')

    atom_spec = [l.strip().split()[1]
                 for l in data[atom_bg_line: atom_ed_line]]
    atom_cord = [l.strip().split()[6:9]
                 for l in data[atom_bg_line: atom_ed_line]]
    atom_cord = np.array(atom_cord, dtype=float)
    if is_cart:
        atom_cord *= alat

    latt = [l.strip().split()[3:6] for l in data[latt_bg_line: latt_ed_line]]
    latt = np.array(latt, dtype=float) * alat

    return latt, atom_spec, atom_cord, is_cart


def qe2cif(qe_file, cif_file):
    """
    Quantum Espresso --> CIF
    """
    from pymatgen.io.cif import CifWriter
    from pymatgen.core.structure import Structure

    lattice, species, coords, is_cart = read_qe_output(qe_file)
    pmg_struc = Structure(lattice=lattice, species=species,
                          coords=coords, coords_are_cartesian=is_cart)
    CifWriter(pmg_struc, symprec=True).write_file(cif_file)

    return


def cif2qe(cif_file, qe_file):
    """
    CIF --> Quantum Espresso cards
    """
    import numpy as np
    from pymatgen.io.cif import CifParser

    print('Notice: CIF files with 1 configuration are permitted.')
    pmg_struc = CifParser(cif_file).get_structures()[0]
    latt_mx = np.array(pmg_struc.lattice.as_dict()['matrix'], dtype=float)
    output = open(qe_file, 'w')
    output.write('%s\n' % 'CELL_PARAMETERS {angstrom}')
    output.write('%15.10f%4s%15.10f%4s%15.10f\n' %
                 (latt_mx[0, 0], '', latt_mx[0, 1], '', latt_mx[0, 2]))
    output.write('%15.10f%4s%15.10f%4s%15.10f\n' %
                 (latt_mx[1, 0], '', latt_mx[1, 1], '', latt_mx[1, 2]))
    output.write('%15.10f%4s%15.10f%4s%15.10f\n' %
                 (latt_mx[2, 0], '', latt_mx[2, 1], '', latt_mx[2, 2]))
    output.write('\n')
    output.write('%s\n' % 'ATOMIC_POSITIONS {angstrom}')
    cart_coord = pmg_struc.cart_coords.tolist()
    for i in range(pmg_struc.num_sites):
        output.write(
            '%3s%16.8f%16.8f%16.8f\n' %
            (str(pmg_struc.species[i]), cart_coord[i]
             [0], cart_coord[i][1], cart_coord[i][2])
        )

    output.write('\n')
    output.write('%15s%4i\n' %
                 ('space_group =', pmg_struc.get_space_group_info()[1]))
    output.write('%15s%16.8f\n' %
                 ('a =', pmg_struc.lattice.a / 0.529177210903))
    output.write('%15s%16.8f\n' %
                 ('b/a =', pmg_struc.lattice.b / pmg_struc.lattice.a))
    output.write('%15s%16.8f\n' %
                 ('c/a =', pmg_struc.lattice.c / pmg_struc.lattice.a))
    output.write('%15s%16.8f\n' %
                 ('cos(bc) =', np.cos(pmg_struc.lattice.alpha / 180 * np.pi)))
    output.write('%15s%16.8f\n' %
                 ('cos(ac) =', np.cos(pmg_struc.lattice.beta / 180 * np.pi)))
    output.write('%15s%16.8f\n' %
                 ('cos(ab) =', np.cos(pmg_struc.lattice.gamma / 180 * np.pi)))
    output.close()

    return


option = input(
    'Options: 1. qe2cif  2. cif2qe; Type either option name or number: ')
if option == 'qe2cif' or int(option) == 1:
    qe_file = input('Enter the Quantum Espresso pw.x output file: ')
    cif_file = input('Enter the name of CIF file: ')
    qe2cif(qe_file, cif_file)
elif option == 'cif2qe' or int(option) == 2:
    cif_file = input('Enter the name of CIF file: ')
    qe_file = input('Enter the name of Quantum Espresso keyword / card file: ')
    cif2qe(cif_file, qe_file)
else:
    print('ERROR: Available options: 1. qe2cif  2. cif2qe, type either option name or number')


