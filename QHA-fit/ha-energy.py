#!/usr/bin/env python
# coding: utf-8

# To calculate Helmoltz & Gibbs free energy at different temperatures and muptiple volumes under harmonic approximation. Based on CRYSTAL17 output file '.out'. Required files & input parameters: 
# 
# * Harmonic phonon calculation output by CRYSTAL17
# * Temperature range
# * The name list of harmonic phonon outputs, stored with temperature range in 'HA_input.dat'
#     
# By Spica. Vir., ICL, Mar 07 - 22. spica.h.zhou@gmail.com

# **Equations:**
# * Helmoltz free energy: $A(T)=U_{0}+\sum_{i}\frac{1}{2}\hbar\omega_{i}+k_{B}T\sum_{i} \left[ln \left(1-e^{-\frac{\hbar\omega_{i}}{k_{B}T}} \right) \right]$, $\omega_{i}=2\pi\nu_{i}$
# * Gibbs free energy: $G(T)=A(T)+pV$
# 
# **Units**
# * Lattice volume: $A^{3}$ and $cm^{3}.mol^{-1}$. N.B. Per mole simulation cell.
# * Pressure: $MPa$
# * Vibrational frequency: $2\pi THz$
# * Energies: $kJ.mol^{-1}$. N.B. Per mole simulation cell.

# In[27]:


import math
import os

class Mode:
    """
    mode class - store frequency and calculate mode-specific free energies
    """

    def __init__(self, freq=0):
        # Unit: THz
        self.freq = freq * 2 * math.pi

    def energies(self, T=298.15, hbar=1.0545718, kb=1.3806485):
        if T == 0:
            self.entS = 0
        else:
            self.entS = math.log(1 - math.exp(-hbar * self.freq * 10 / kb / T))
        return self


# In[34]:


class FreeE:
    """
    FreeE class - store energy terms and calculate the free energies of the system
    """

    def __init__(self, edft=0, ez=0, pv=0, pre=0, modes=[]):
        self.edft = edft
        self.ez = ez
        self.pv = pv
        self.pre = pre
        self.modes = modes

    def cal_vol(self):
        self.va = self.pv / self.pre / 6.0221407e-4
        self.vb = self.pv / self.pre * 1000
        return self

    def cleardata(self):
        """
        Remove the negative frequencies and print warning message. 
        """
        if self.modes[0].freq < -1e-4:
            print('WARNING: Negative frequencies detected - Calculated free energies might be inaccurate.')

        self.modes = [i for i in self.modes if i.freq > 1e-4]
        return self

    def energies(self, T=298.15, kb=1.3806485, na=6.0221407):
        #         hbar = 1.0545718
        #         zpt = [0.5 * i.freq * hbar * na / 100 for i in self.modes]
        entS = [i.entS for i in self.modes]
        self.helmoltz = self.edft + self.ez + sum(entS) * T * kb * na * 1e-3
        self.gibbs = self.helmoltz + self.pv
        return self


# In[3]:


class Cell:
    """
    Class Cell, store the lattice parameters of simulation cell and reduce them to the simplest form. 
    N.B. Geometry data for determining the demension of QHA Hessian matrix only.
    """
    def __init__(self, a=0, b=0, c=0, alpha=0, beta=0, gamma=0):
        self.a = float(a)
        self.b = float(b)
        self.c = float(c)
        self.alpha = float(alpha)
        self.beta = float(beta)
        self.gamma = float(gamma)
        
    def reduce(self):
        self.len = [self.a]
        self.ang = []
        if abs(self.b - self.a) >= 1e-5:
            self.len.append(self.b)
        
        if (abs(self.c - self.a) >= 1e-5) and (abs(self.c - self.b) >= 1e-5):
            self.len.append(self.c)
            
        if (abs(self.alpha - 90.) >= 1e-5):
            self.ang.append(self.alpha)
        
        if abs(self.beta - 90.) >= 1e-5:
            self.ang.append(self.beta)
            
        if abs(self.gamma - 90.) >= 1e-5:
            self.ang.append(self.gamma)
        
        # Hexagonal lattice
        if (len(self.ang) == 1) and (self.ang[0] % 60. <= 1e-5):
            self.ang = []
            
        return self


# In[4]:


def readfreq(data):
    """
    Read and generate modes object
    """
    modes = []
    countline = 0
    label = 'MODES         EIGV          FREQUENCIES     IRREP  IR   INTENS    RAMAN'
    while countline < len(data) - 1:
        currline = data[countline]
        if label in currline:
            countline += 2
            currline = data[countline].strip().split()
            while len(currline) != 0:
                m_bg = int(currline[0].strip('-'))
                m_ed = int(currline[1]) + 1
                freq = float(currline[4])
                # Different modes with the same frequency
                for m in range(m_bg, m_ed):
                    a_mode = Mode(freq=freq)
                    modes.append(a_mode)

                countline += 1
                currline = data[countline].strip().split()

            break

        countline += 1

    return modes


# In[5]:


def readenergy(data, free_energy):
    """
    Get other energy terms & conditions, generate free_eng object
    """
    countline = len(data) - 1
    lb_pv = 'PV            :'
    while countline >= 0:
        currline = data[countline]
        if lb_pv in currline:
            free_energy.pv = float(currline.strip().split()[4])
            free_energy.pre = float(data[countline - 4].strip().split()[7])
            free_energy.ez = float(data[countline - 11].strip().split()[4])
            free_energy.edft = float(data[countline - 12].strip().split()[4])
            free_energy = free_energy.cal_vol()
            break

        countline -= 1

    return free_energy


# In[6]:


def readgeom(data):
    """
    Read geometry parameters from output. 
    """
    countline = 0
    label = 'LATTICE PARAMETERS  (ANGSTROMS AND DEGREES) - PRIMITIVE CELL'
    while countline < len(data) - 1:
        currline = data[countline]
        if label in currline:
            countline += 2
            currline = data[countline].strip().split()
            cell_para = Cell(a=currline[0], b=currline[1], c=currline[2], alpha=currline[3], beta=currline[4], gamma=currline[5])
            cell_para = cell_para.reduce()
            break
        
        countline += 1
    
    return cell_para


# In[8]:


def writeout_a_geom(data, temperature, name='HA_ef.dat'):
    modes = readfreq(data)
    cell_para = readgeom(data)
    free_energy = FreeE(modes=modes)
    free_energy = readenergy(data, free_energy)
    free_energy = free_energy.cleardata()
    
    name = os.path.splitext(name)[0]
    name = name = 'HA_ef_' + name + '.dat'

    wtout = open(name, "w")
    wtout.write('%-15s%-12.6f%-4s\n'
             % ('PRESSURE = ', free_energy.pre, 'MPa'))
    wtout.write('%-15s%-12.6f%-4s%-3s%-12.6f%7s\n'
             % ('CELL VOLUME = ', free_energy.va, 'A^3', '=', free_energy.vb, 'CM^3/MOL'))

    wtout.write('%-s\n' % 'IRREDUCIBLE LATTICE PARAMETERS - LENGTH')
    for i in cell_para.len:
        wtout.write('%-16.5f' % i)

    wtout.write('\n%-s\n' % 'IRREDUCIBLE LATTICE PARAMETERS - ANGLE')
    for i in cell_para.ang:
        wtout.write('%-16.5f' % i)

    wtout.write('\n%-18s%-18s%18s\n' %
               ('TEMPERATURE(K)', 'HELMOLTZ(KJ/MOL)', 'GIBBS(KJ/MOL)'))

    for t in temperature:
        t = float(t)
        for m in free_energy.modes:
            m = m.energies(T=t)

        free_energy = free_energy.energies(T=t)
        wtout.write('%-18.2f%-18.6f%18.6f\n' %
                   (t, free_energy.helmoltz, free_energy.gibbs))

    wtout.close()


# In[38]:


################ HA_input.dat format ################
# TEMPERATURE
# [temperature list, 1 dimension]
# FILES
# [file1.out]
# [file2.out]
# ...
# END


# In[25]:


def readnamelist():
    file = open('HA_input.dat', "r")
    data_in = file.readlines()
    file.close()
    
    labelt = 'TEMPERATURE'
    labelf = 'FILES'
    labele = 'END'
    countline = 0
    filelist = []
    while countline < len(data_in):
        if labelt in data_in[countline]:
            countline += 1
            tempt = data_in[countline].strip().split()
        
        if labelf in data_in[countline]:
            countline += 1
            while labele not in data_in[countline]:
                filelist.append(data_in[countline].strip())
                countline += 1
        
        countline += 1
    
    tempt = [float(t) for t in tempt]
    return filelist, tempt


# In[37]:


filelist, tempt = readnamelist()

for i in filelist:
    file = open(i, "r")
    data = file.readlines()
    file.close()
    writeout_a_geom(data, tempt, name=i)
    

