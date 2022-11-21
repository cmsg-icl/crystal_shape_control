#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Unit and constant systems of QHA-model.
"""
import sys
import scipy.constants as cst

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
        self.__assign_hartree()

    def redefine(self, unit):
        method = {
            'HARTREE' : self.__assign_hartree(),
            'METRIC'  : self.__assign_metric()
        }
        try: 
            method[unit]
        except KeyError:
            print('Unit system specified is not defined.')
            traceback.print_exc()

    def __assign_hartree(self):
        """
        Assign constants and unit conversion parameters based on Hartree atomic
        unit system
        """
        self._pi       = cst.pi
        self._rad      = cst.pi / 180.
        self._deg      = 1.
        self._h        = 2. * cst.pi
        self._hbar     = 1.
        self._kb       = cst.k * cst.physical_constants['Hartree energy'][0]**-1
        self._na       = cst.Avogadro
        self._c        = cst.c *  cst.hbar *  cst.physical_constants['Bohr radius'][0]**-1 * cst.physical_constants['Hartree energy'][0]**-1
        self._epsilon0 = 0.25 * cst.pi**-1
        self._me       = 1.
        self._e        = 1.
        self._mau      = cst.m_e * cst.physical_constants['unified atomic mass unit'][0]**-1
        self._j        = cst.physical_constants['Hartree energy'][0]
        self._kjmol    = cst.physical_constants['Hartree energy'][0] * 1e-3 * cst.Avogadro
        self._kcalmol  = cst.physical_constants['Hartree energy'][0] * 1e-3 * cst.Avogadro / 4.184 # https://en.wikipedia.org/wiki/Calorie
        self._eV       = cst.physical_constants['electron volt-hartree relationship'][0]**-1
        self._ha       = 1.
        self._ry       = 2.
        self._ang      = cst.physical_constants['Bohr radius'][0] * cst.physical_constants['Angstrom star'][0]**-1
        self._br       = 1.
        self._cmmol    = 1e2 * cst.physical_constants['Bohr radius'][0] * cst.Avogadro 
        self._ang2     = cst.physical_constants['Bohr radius'][0]**2 * cst.physical_constants['Angstrom star'][0]**-2
        self._br2      = 1.
        self._cm2mol   = 1e4 * cst.physical_constants['Bohr radius'][0]**2 * cst.Avogadro
        self._ang3     = cst.physical_constants['Bohr radius'][0]**3 * cst.physical_constants['Angstrom star'][0]**-3
        self._br3      = 1.
        self._cm3mol   = 1e6 * cst.physical_constants['Bohr radius'][0]**3 * cst.Avogadro
        self._k        = 1.
        self._s        = cst.physical_constants['inverse fine-structure constant'][0] * cst.c**-1 * cst.physical_constants['Bohr radius'][0]
        self._tau      = 1.
        self._thz      = 1e-12 * cst.physical_constants['fine-structure constant'][0] * cst.c * cst.physical_constants['Bohr radius'][0]**-1
        self._cm_1     = 1e-2 * cst.physical_constants['fine-structure constant'][0] * cst.physical_constants['Bohr radius'][0]**-1
        self._fau      = 1.
        self._mpa      = 1e-6 * cst.physical_constants['Hartree energy'][0] * cst.physical_constants['Bohr radius'][0]**-3
        self._gpa      = 1e-9 * cst.physical_constants['Hartree energy'][0] * cst.physical_constants['Bohr radius'][0]**-3
        self._pau      = 1.
        self._jmolk    = cst.physical_constants['Hartree energy'][0] * cst.Avogadro
        self._sau      = 1.
        
        return self

    def __assign_metric(self):
        """
        Assign constants and unit conversion parameters based on metric system
        Rarely tested and not recommanded!
        """
        self._pi       = cst.pi
        self._rad      = cst.pi / 180.
        self._deg      = 1.
        self._h        = cst.h
        self._hbar     = cst.hbar
        self._kb       = cst.k
        self._na       = cst.Avogadro
        self._c        = cst.c
        self._epsilon0 = cst.epsilon_0
        self._me       = cst.m_e**-1
        self._mau      = cst.physical_constants['unified atomic mass unit'][0]**-1
        self._j        = 1.
        self._kjmol    = 1e-3 * cst.Avogadro
        self._kcalmol  = 1e-3 * cst.Avogadro / 4.184 # https://en.wikipedia.org/wiki/Calorie
        self._ev       = cst.physical_constants['electron volt'][0]**-1
        self._ha       = cst.physical_constants['Hartree energy'][0]**-1
        self._ry       = 2 * cst.physical_constants['Hartree energy'][0]**-1
        self._ang      = cst.physical_constants['Angstrom star'][0]**-1
        self._br       = cst.physical_constants['Bohr radius'][0]**-1
        self._cmmol    = 1e2 * cst.Avogadro
        self._ang2     = cst.physical_constants['Angstrom star'][0]**-2
        self._br2      = cst.physical_constants['Bohr radius'][0]**-2
        self._cm2mol   = 1e4 * cst.Avogadro
        self._ang3     = cst.physical_constants['Angstrom star'][0]**-3
        self._br3      = cst.physical_constants['Bohr radius'][0]**-3
        self._cm3mol   = 1e6 * cst.Avogadro
        self._k        = 1.
        self._s        = 1.
        self._tau      = cst.c * cst.physical_constants['fine-structure constant'][0] * cst.physical_constants['Bohr radius'][0]**-1
        self._thz      = 1e-12
        self._cm_1     = 1e-2 * cst.c**-1
        self._fau      = cst.physical_constants['inverse fine-structure constant'][0] * cst.c**-1 * cst.physical_constants['Bohr radius'][0]
        self._mpa      = 1e-6
        self._gpa      = 1e-9
        self._pau      = cst.physical_constants['Bohr radius'][0]**3 * cst.physical_constants['Hartree energy'][0]**-1
        self._jmolk    = cst.Avogadro
        self._sau      = cst.physical_constants['Hartree energy'][0]**-1
        
        return self

constant = Constants()
sys.modules[__name__] = constant