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
    from scipy import constants

    file = open(qe_file, 'r', errors='ignore')
    data = file.readlines()
    file.close()

    atom_block_flag = False
    coord_type = ''
    for i, line in enumerate(data):
        if re.match(r'^\s+site n\.\s+atom\s+positions \(alat units\)', line):
            atom_bg_line = i + 1
            coord_type = 'alat'
            atom_block_flag = True
            continue
        if re.match(r'^ATOMIC_POSITIONS \(angstrom\)', line):
            atom_bg_line = i + 1
            coord_type = 'cart'
            atom_block_flag = True
            continue
        elif re.match(r'^ATOMIC_POSITIONS \(crystal\)', line):
            atom_bg_line = i + 1
            coord_type = 'frac'
            atom_block_flag = True
            continue
        elif atom_block_flag and len(line.strip()) == 0:
            atom_ed_line = i
            atom_block_flag = False
            continue
        elif atom_block_flag and re.match(r'^End final coordinates', line):
            atom_ed_line = i
            atom_block_flag = False
            continue
        elif re.match(r'^\s+lattice parameter \(alat\)  =', line):
            alat = float(line.strip().split()[4]) * constants.physical_constants['atomic unit of length'][0] * 1e10
            continue
        elif re.match(r'^\s+crystal axes\: \(cart\. coord\. in units of alat\)', line):
            latt_bg_line = i + 1
            continue
        elif re.match(r'^\s+reciprocal axes\: \(cart\. coord\. in units', line):
            latt_ed_line = i - 1
            continue
        else:
            continue

    if coord_type == '':
        raise Exception('Atomic coord. block not identified')
    if 'latt_bg_line' not in locals().keys():
        raise Exception('Latt. block not identified')

    print('\nPlease check: \nLattice starting line = {}\nLattice ending line = {}\n'.format(latt_bg_line + 1, latt_ed_line + 1))
    print('Please check: \nAtomic coordinate starting line = {}\nAtomic coordinate ending line = {}\n'.format(atom_bg_line + 1, atom_ed_line + 1))
    print('Please check: \nAlat unit = {:.4f} Angstrom\n'.format(alat))

    latt = [l.strip().split()[3:6] for l in data[latt_bg_line: latt_ed_line]]
    latt = np.array(latt, dtype=float) * alat

    atom_spec = []
    atom_cord = []
    for l in data[atom_bg_line: atom_ed_line]:
        atom_spec.append(re.findall(r'[A-Z]{1}[a-z,A-Z]{0}', l)[0])
        atom_cord.append(re.findall(r'[0-9,\-]+\.[0-9]{7,}', l))
    atom_cord = np.array(atom_cord, dtype=float)
    if coord_type == 'alat':
        atom_cord *= alat
    elif coord_type == 'frac':
        atom_cord = np.dot(atom_cord, latt)

    return latt, atom_spec, atom_cord


def qe2cif(qe_file, cif_file, symm):
    """
    Quantum Espresso --> CIF
    """
    from pymatgen.io.cif import CifWriter
    from pymatgen.core.structure import Structure

    lattice, species, coords = read_qe_output(qe_file)
    pmg_struc = Structure(lattice=lattice, species=species,
                          coords=coords, coords_are_cartesian=True)
    if symm == True:
        CifWriter(pmg_struc, symprec=True).write_file(cif_file)
    else:
        CifWriter(pmg_struc, symprec=None).write_file(cif_file)

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
                 ('celldm(1) =', pmg_struc.lattice.a / 0.529177210903))
    output.write('%15s%16.8f\n' %
                 ('celldm(2) =', pmg_struc.lattice.b / pmg_struc.lattice.a))
    output.write('%15s%16.8f\n' %
                 ('celldm(3) =', pmg_struc.lattice.c / pmg_struc.lattice.a))
    output.write('%15s%16.8f\n' %
                 ('celldm(4) =', np.cos(pmg_struc.lattice.alpha / 180 * np.pi)))
    output.write('%15s%16.8f\n' %
                 ('celldm(5) =', np.cos(pmg_struc.lattice.beta / 180 * np.pi)))
    output.write('%15s%16.8f\n' %
                 ('celldm(6) =', np.cos(pmg_struc.lattice.gamma / 180 * np.pi)))
    output.close()

    return


option = input('Options: 1. qe2cif  2. cif2qe; Type either option name or number: ')
if option == 'qe2cif' or int(option) == 1:
    qe_file = input('Enter the Quantum Espresso pw.x output file: ')
    cif_file = input('Enter the name of CIF file: ')
    symm = input('Write symmetry? 0: No  1: Yes; Type either option name or number: ')
    if symm == 'No' or int(symm) == 0:
        qe2cif(qe_file, cif_file, False)
    elif symm == 'Yes' or int(symm) == 1:
        qe2cif(qe_file, cif_file, True)
    else:
        raise ValueError('Available options: 0: No  1: Yes. Type either option name or number.')

elif option == 'cif2qe' or int(option) == 2:
    cif_file = input('Enter the name of CIF file: ')
    qe_file = input('Enter the name of Quantum Espresso keyword / card file: ')
    cif2qe(cif_file, qe_file)
else:
    raise ValueError('Available options: 1. qe2cif  2. cif2qe, type either option name or number.')


