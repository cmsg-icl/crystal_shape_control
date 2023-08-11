#!/bin/env python
"""
Transform geometry from Materials Studio to Quantum Espresso pw.x input keywod
/ card file. Constrains on atomic coordinates are read and printed.

By Spical. Vir., ICL, spica.h.zhou@gmail.com
22:20:48, Aug.11, 23
"""
def xsd_parser(filename):
    """
    XML file parser
    """
    from xml.dom import minidom
    import numpy as np

    DOMtree = minidom.parse(filename)
    structure = DOMtree.documentElement

    # Atom informations
    atoms = structure.getElementsByTagName('Atom3d')
    # atom_id = []
    atom_element = []
    atom_frac = []
    atom_rstct = []
    for a in atoms:
        # atom_id.append(a.getAttribute('ID'))
        atom_element.append(a.getAttribute('Components'))
        atom_frac.append(a.getAttribute('XYZ').split(','))
        atom_rstct.append(a.getAttribute('RestrictedProperties'))

    # atom_id = np.array(atom_id, dtype=int)
    atom_frac = np.array(atom_frac, dtype=float)

    # Lattice
    box = structure.getElementsByTagName('SpaceGroup')
    lattice = [box[0].getAttribute('AVector').split(','),
               box[0].getAttribute('BVector').split(','),
               box[0].getAttribute('CVector').split(',')]
    lattice = np.array(lattice, dtype=float)
    sg = int(box[0].getAttribute('ITNumber'))

    return lattice, sg, atom_element, atom_frac, atom_rstct

def output_printer(xml, qe):
    """
    Print QE formatted geometry output
    """
    from pymatgen.core.lattice import Lattice
    from scipy import constants
    import numpy as np

    latt_mx, sg, atom_element, atom_frac, atom_rstct = xsd_parser(xml)

    file = open(qe, 'w')
    file.write('%s\n' % 'CELL_PARAMETERS {angstrom}')
    for l in latt_mx:
        file.write('%15.10f%19.10f%19.10f\n' % (l[0], l[1], l[2]))
    file.write('\n')

    atom_cart = np.dot(atom_frac, latt_mx)
    file.write('%s\n' % 'ATOMIC_POSITIONS {angstrom}')
    rstct_map = {'XYZ' : '0 0 0',
                 'XY'  : '0 0 1',
                 'XZ'  : '0 1 0',
                 'YZ'  : '1 0 0',
                 'X'   : '0 1 1',
                 'Y'   : '1 0 1',
                 'Z'   : '1 1 0'}
    for i in range(len(atom_element)):
        file.write('%3s%16.8f%16.8f%16.8f' % (atom_element[i], atom_cart[i, 0],
                                              atom_cart[i, 1], atom_cart[i, 2]))
        if atom_rstct[i] != '':
            cart_constraint = atom_rstct[i].split(',')[0]
            file.write('%4s%s' % ('', rstct_map[cart_constraint]))
        file.write('\n')
    file.write('\n')

    file.write('%15s%3i\n' % ('space_group =', sg))
    lattice = Lattice(latt_mx)
    a = lattice.a / (constants.physical_constants['atomic unit of length'][0] * 1e10)
    file.write('%15s%16f\n' % ('a =', a))
    file.write('%15s%16f\n' % ('b/a =', lattice.b / lattice.a))
    file.write('%15s%16f\n' % ('c/a =', lattice.c / lattice.a))
    file.write('%15s%16f\n' % ('cos(bc) =', np.cos(lattice.alpha * np.pi / 180)))
    file.write('%15s%16f\n' % ('cos(ac) =', np.cos(lattice.beta * np.pi / 180)))
    file.write('%15s%16f\n' % ('cos(ab) =', np.cos(lattice.gamma * np.pi / 180)))
    file.close()

ms = input('Materials Studio xsd file: ')
qe = input('Quantum Espresso keyword / card file: ')
output_printer(ms, qe)
