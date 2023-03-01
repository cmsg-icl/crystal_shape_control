#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Unit and constant systems of QHA-model.

Developers Note:
This module should be loaded as a global constant object using the following
commands at the beginning of scripts: 
    import constants as cst
    global cst
"""
import sys
import traceback
import scipy.constants as scst


class Constants:
    @property
    def pi(self):
        # Pi
        return self._pi

    @property
    def rad(self):
        # Radian
        return self._rad

    @property
    def deg(self):
        # Arc degree
        return self._deg

    @property
    def h(self):
        # Planck constant
        return self._h

    @property
    def hbar(self):
        # Reduced Planck constant
        return self._hbar

    @property
    def kb(self):
        # Boltzmann constant
        return self._kb

    @property
    def na(self):
        # Avogadro constant
        return self._na

    @property
    def c(self):
        # Speed of light in vacuum
        return self._c

    @property
    def epsilon0(self):
        # Vacuum permittivity
        return self._epsilon0

    @property
    def me(self):
        # Electron mass
        return self._me

    @property
    def e(self):
        # Elementary charge
        return self._e

    @property
    def mau(self):
        # Unified atomic mass
        return self._mau

    @property
    def j(self):
        # Energy in J
        return self._j

    @property
    def kjmol(self):
        # Energy in kJ / mol
        return self._kjmol

    @property
    def kcalmol(self):
        # Energy in thermochemical kcal / mol
        return self._kcalmol

    @property
    def ev(self):
        # Energy in electron volt
        return self._ev

    @property
    def ha(self):
        # Energy in Hartree unit
        return self._ha

    @property
    def ry(self):
        # Energy in Rydberg unit
        return self._ry

    @property
    def ang(self):
        # Length in Angstrom
        return self._ang

    @property
    def br(self):
        # Length in Bohr radius
        return self._br

    @property
    def cmmol(self):
        # Length in cm / mol, For 1D systems
        return self._cmmol

    @property
    def ang2(self):
        # Area in Angstrom^2
        return self._ang2

    @property
    def br2(self):
        # Area in Bohr^2
        return self._br2

    @property
    def cm2mol(self):
        # Area in cm^2 / mol, For 2D systems
        return self._cm2mol

    @property
    def ang3(self):
        # Volume in Angstrom^3
        return self._ang3

    @property
    def br3(self):
        # Volume in Bohr^3
        return self._br3

    @property
    def cm3mol(self):
        # Volume in cm^3 / mol, For 3D systems
        return self._cm3mol

    @property
    def k(self):
        # Temperature in K
        return self._k

    @property
    def s(self):
        # Time in s
        return self._s

    @property
    def tau(self):
        # Time in Hartree unit
        return self._tau

    @property
    def thz(self):
        # Frequency in THz
        return self._thz

    @property
    def cm_1(self):
        # Frequency in cm^-1
        return self._cm_1

    @property
    def fau(self):
        # Frequency in Hartree unit
        return self._fau

    @property
    def mpa(self):
        # Pressure / moduli in MPa
        return self._mpa

    @property
    def gpa(self):
        # Pressure / moduli in GPa
        return self._gpa

    @property
    def pau(self):
        # Pressure / moduli in Hartree unit
        return self._pau

    @property
    def jmolk(self):
        # Specific heat / entropy in J.mol^-1.K^-1
        return self._jmolk

    @property
    def sau(self):
        # Specific heat / entropy in Hartree unit
        return self._sau

    def __init__(self):
        self._assign_hartree()

    def redefine(self, unit):
        import scipy.constants as scst

        method = {
            'HARTREE': 'self._assign_hartree()',
            'METRIC': 'self._assign_metric()'
        }

        param = {'self': self}
        try:
            exec(method[unit], param)
        except KeyError:
            print('Unit system specified is not defined.')
            traceback.print_exc()

        return self

    def _assign_hartree(self):
        """
        Assign constants and unit conversion parameters based on Hartree atomic
        unit system
        """
        import scipy.constants as scst

        self._pi = scst.pi
        self._rad = scst.pi / 180.
        self._deg = 1.
        self._h = 2. * scst.pi
        self._hbar = 1.
        self._kb = scst.k * scst.physical_constants['Hartree energy'][0]**-1
        self._na = scst.Avogadro
        self._c = scst.c * scst.hbar * \
            scst.physical_constants['Bohr radius'][0]**-1 * \
            scst.physical_constants['Hartree energy'][0]**-1
        self._epsilon0 = 0.25 * scst.pi**-1
        self._me = 1.
        self._e = 1.
        self._mau = scst.m_e * \
            scst.physical_constants['unified atomic mass unit'][0]**-1
        self._j = scst.physical_constants['Hartree energy'][0]
        self._kjmol = scst.physical_constants['Hartree energy'][0] * \
            1e-3 * scst.Avogadro
        # https://en.wikipedia.org/wiki/Calorie
        self._kcalmol = scst.physical_constants['Hartree energy'][0] * \
            1e-3 * scst.Avogadro / 4.184
        self._ev = scst.physical_constants['electron volt-hartree relationship'][0]**-1
        self._ha = 1.
        self._ry = 2.
        self._ang = scst.physical_constants['Bohr radius'][0] * \
            scst.physical_constants['Angstrom star'][0]**-1
        self._br = 1.
        self._cmmol = 1e2 * \
            scst.physical_constants['Bohr radius'][0] * scst.Avogadro
        self._ang2 = scst.physical_constants['Bohr radius'][0]**2 * \
            scst.physical_constants['Angstrom star'][0]**-2
        self._br2 = 1.
        self._cm2mol = 1e4 * \
            scst.physical_constants['Bohr radius'][0]**2 * scst.Avogadro
        self._ang3 = scst.physical_constants['Bohr radius'][0]**3 * \
            scst.physical_constants['Angstrom star'][0]**-3
        self._br3 = 1.
        self._cm3mol = 1e6 * \
            scst.physical_constants['Bohr radius'][0]**3 * scst.Avogadro
        self._k = 1.
        self._s = scst.physical_constants['inverse fine-structure constant'][0] * \
            scst.c**-1 * scst.physical_constants['Bohr radius'][0]
        self._tau = 1.
        self._thz = 1e-12 * \
            scst.physical_constants['fine-structure constant'][0] * \
            scst.c * scst.physical_constants['Bohr radius'][0]**-1
        self._cm_1 = 1e-2 * \
            scst.physical_constants['fine-structure constant'][0] * \
            scst.physical_constants['Bohr radius'][0]**-1
        self._fau = 1.
        self._mpa = 1e-6 * \
            scst.physical_constants['Hartree energy'][0] * \
            scst.physical_constants['Bohr radius'][0]**-3
        self._gpa = 1e-9 * \
            scst.physical_constants['Hartree energy'][0] * \
            scst.physical_constants['Bohr radius'][0]**-3
        self._pau = 1.
        self._jmolk = scst.physical_constants['Hartree energy'][0] * \
            scst.Avogadro
        self._sau = 1.

        return self

    def _assign_metric(self):
        """
        Assign constants and unit conversion parameters based on metric system
        Rarely tested and not recommanded!
        """
        import scipy.constants as scst

        self._pi = scst.pi
        self._rad = scst.pi / 180.
        self._deg = 1.
        self._h = scst.h
        self._hbar = scst.hbar
        self._kb = scst.k
        self._na = scst.Avogadro
        self._c = scst.c
        self._epsilon0 = scst.epsilon_0
        self._me = scst.m_e**-1
        self._mau = scst.physical_constants['unified atomic mass unit'][0]**-1
        self._j = 1.
        self._kjmol = 1e-3 * scst.Avogadro
        # https://en.wikipedia.org/wiki/Calorie
        self._kcalmol = 1e-3 * scst.Avogadro / 4.184
        self._ev = scst.physical_constants['electron volt'][0]**-1
        self._ha = scst.physical_constants['Hartree energy'][0]**-1
        self._ry = 2 * scst.physical_constants['Hartree energy'][0]**-1
        self._ang = scst.physical_constants['Angstrom star'][0]**-1
        self._br = scst.physical_constants['Bohr radius'][0]**-1
        self._cmmol = 1e2 * scst.Avogadro
        self._ang2 = scst.physical_constants['Angstrom star'][0]**-2
        self._br2 = scst.physical_constants['Bohr radius'][0]**-2
        self._cm2mol = 1e4 * scst.Avogadro
        self._ang3 = scst.physical_constants['Angstrom star'][0]**-3
        self._br3 = scst.physical_constants['Bohr radius'][0]**-3
        self._cm3mol = 1e6 * scst.Avogadro
        self._k = 1.
        self._s = 1.
        self._tau = scst.c * \
            scst.physical_constants['fine-structure constant'][0] * \
            scst.physical_constants['Bohr radius'][0]**-1
        self._thz = 1e-12
        self._cm_1 = 1e-2 * scst.c**-1
        self._fau = scst.physical_constants['inverse fine-structure constant'][0] * \
            scst.c**-1 * scst.physical_constants['Bohr radius'][0]
        self._mpa = 1e-6
        self._gpa = 1e-9
        self._pau = scst.physical_constants['Bohr radius'][0]**3 * \
            scst.physical_constants['Hartree energy'][0]**-1
        self._jmolk = scst.Avogadro
        self._sau = scst.physical_constants['Hartree energy'][0]**-1

        return self

constant = Constants()
sys.modules[__name__] = constant