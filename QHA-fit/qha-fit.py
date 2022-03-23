#!/usr/bin/env python
# coding: utf-8

# Script for fitting Helmholtz free energy under quasi-harmonic approximation. Equilibrium lattice parameters and Helmholtz free energy at a given temperature are fitted with harmonic phonons on various volumes. Methods are detailed in the following reference: 
# 
# - N. Raimbault, V. Athavale and M. Rossi, *Phys. Rev. Materials*, 2019, **3**, 053605.
# 
# By Spica. Vir., ICL, Mar 07 - 22. spica.h.zhou@gmail.com
# 
# Helmholtz free energy at a given temperature is Taylor expanded around the equilibrium lattice parameters. Taking Form I paracetamol lattice as the example (Monoclinic, P2_1/n, Space group 14): 
# 
# $F \left(a, b, c, \beta \right)=F \left(a_{0}, b_{0}, c_{0}, \beta_{0} \right) + \mathbf{p}\mathbf{H}\mathbf{p}^{T}$
# 
# $\mathbf{H}=\begin{pmatrix}
# \frac{\partial^{2}F}{\partial a^{2}} & \cdots & \cdots & \cdots \\
# \frac{\partial^{2}F}{\partial b \partial a} & \frac{\partial^{2}F}{\partial b^{2}} & \cdots & \cdots \\
# \frac{\partial^{2}F}{\partial c \partial a} & \frac{\partial^{2}F}{\partial c \partial b} & \frac{\partial^{2}F}{\partial c^{2}} & \cdots \\
# \frac{\partial^{2}F}{\partial \beta \partial a} & \frac{\partial^{2}F}{\partial \beta \partial b} & \frac{\partial^{2}F}{\partial \beta \partial c} & \frac{\partial^{2}F}{\partial \beta^{2}} \\
# \end{pmatrix}$
# 
# $\mathbf{p}= \left(\delta a, \delta b, \delta c, \delta\beta \right)$
# 
# The equilibrium Helmholtz free energy $F_{0}$, equilibrium lattice parameters $\left(a_{0}, b_{0}, c_{0}, \beta_{0} \right)$ and independent elements of $\mathbf{H}$ are fitted by least mean square fitting. 

# In[2]:


import numpy as np
from scipy.optimize import least_squares
import os


# In[3]:


class Inpdata:
    """
    Class Inpdata, read and store HA reference file name list and temperature list for class Refdata and QHA fitting
    """
    def __init__(self):
        self.nlist = []
        self.tlist = []
        
    def readinput(self):
        """
        Read the input data - file names and temperature sequence. Input is named as 'HA_input.dat' only.
        """
        file = open('HA_input.dat', "r")
        data_in = file.readlines()
        file.close()
    
        labelt = 'TEMPERATURE'
        labelf = 'FILES'
        labele = 'END'
        countline = 0
        while countline < len(data_in):
            if labelt in data_in[countline]:
                countline += 1
                tempt = data_in[countline].strip().split()
        
            if labelf in data_in[countline]:
                countline += 1
                while labele not in data_in[countline]:
                    self.nlist.append(data_in[countline].strip())
                    countline += 1
        
            countline += 1
    
        self.tlist = [float(t) for t in tempt]
        
        return self


# In[4]:


class Refdata:
    """
    Class Refdata, read and store the reference HA calculation data at a given temperature, including 
    * reference lattice parameters
    * free energy
    * demension of free energy Hessian
    * temperature of data above
    """
    def __init__(self, tempt=0.):
        """
        At a single temperature, 
        Lattice parameters of all reference files are stored in p as a nfile * size list. 
        Free energies of all references are stored in f as a nfile * 1 list
        """
        self.latt = []
        self.ef = []
        self.tempt = float(tempt)
        
    def read_a_data(self, inputfile='HA_ef.dat'):
        """
        Read a single HA reference file at a single temperature
        """
        reffile = open(inputfile, 'r')
        refdata = reffile.readlines()
        reffile.close()
        labell = 'IRREDUCIBLE LATTICE PARAMETERS - LENGTH'
        labela = 'IRREDUCIBLE LATTICE PARAMETERS - ANGLE'
        labelt = 'TEMPERATURE(K)'
        
        countline = 0
        p = []
        f = 0.
        while countline < len(refdata):
            if labell in refdata[countline]:
                countline += 1
                p = refdata[countline].strip().split()
                
            if labela in refdata[countline]:
                countline += 1
                angle = refdata[countline].strip().split()
                if len(angle) != 0:
                    p = p + angle
                    
            if labelt in refdata[countline]:
                while 'END' not in refdata[countline]:
                    countline += 1
                    temperature = float(refdata[countline].strip().split()[0])
                    if abs(temperature - self.tempt) < 1e-2:
                        f = float(refdata[countline].strip().split()[1])
                        break
                    
            countline += 1
        
        if (len(p) == 0) or (abs(f - 0) < 1e-6):
            print('Error: Reference data not found!')
            exit()
        
        self.latt.append([float(i) for i in p])
        self.ef = self.ef + [f]
        self.size = len(self.latt[0])
        
        return self
    
    def read_data(self, inputfiles):
        """
        Iterate the function below
        """
        for i in inputfiles:
            name = os.path.splitext(i)[0]
            name = 'HA_ef_' + name + '.dat'
            self.read_a_data(inputfile=name)
            
        return self
        


# In[16]:


class Fitparam:
    def __init__(self, ref):
        """
        Generate the initial guess of parameters.
        Require: a Refdata object at given temperature
        Output: 
            Lattice parameters: The average of input data
            Free energy: The average of input data
            Hessian: Unit matrix
        """
        self.hess = []
        for i in range(ref.size):
            for j in range(i + 1):
                if j == i:
                    self.hess.append(0.)
                else:
                    self.hess.append(0.)
        
        sum_latt = np.array([0 for i in range(ref.size)], dtype=float)
        for i in ref.latt:
            sum_latt = sum_latt + np.array(i, dtype=float)
        
        self.latt = list(sum_latt / len(ref.latt))
        
        sum_ef = 0
        for i in ref.ef:
            sum_ef = sum_ef + i
            
        self.ef = sum_ef / len(ref.ef)
        
    def generate_itarray(self):
        """
        Generate the numpy array of parameters as required by 'scipy.optimize.least_squares'. 
        Return to the generated array which is used for iteration. 
        """
        itarray = self.latt + [self.ef] + self.hess
        itarray = np.array(itarray, dtype=float)
        
        return itarray
    
    def decouple_itarray(self, itarray, hess_size):
        """
        Decouple the array for iteration and re-parameterise the object Fitparam
        """
        self.latt = []
        self.hess = []
        
        self.latt = [itarray[i] for i in range(hess_size)]
        self.ef = itarray[hess_size]
        self.hess = [itarray[i] for i in range(hess_size + 1, len(itarray))]
        
        return self
    
    def restore_hess_mx(self, hess_size):
        """
        Restore the matrix format of Free energy Hessian. 
        Return to a numpy matrix. 
        """
        hess_mx = np.matrix(np.zeros([hess_size, hess_size]), dtype = float)
        for i in range(hess_size):
            sumi = int(i * (i + 1) / 2)
            for j in range(i + 1):
                hess_mx[i, j] = self.hess[sumi + j]
                hess_mx[j, i] = hess_mx[i, j]

        return hess_mx
        
    


# In[17]:


def qha_tylor(para_in, refdata, fitparam):
    """
    Obtain the residual Helmholtz free energy for all reference calculations. 
    Return to array delta f, the minimisation object of fitting. 
    Require: 
        para_in: the numerpy parameter array for iteration
        refdata: a Refdata object for HA calculation references
        fitparam: a Fitparam object for data processing
    """
    
    fitparam.decouple_itarray(itarray=para_in, hess_size=refdata.size)
    hess = fitparam.restore_hess_mx(hess_size=refdata.size)
    deltaf = []
    
    for i in range(len(refdata.latt)):
        ineq_latt = np.matrix(refdata.latt[i], dtype=float)
        eq_latt = np.matrix(fitparam.latt, dtype=float)
        latt_diff = ineq_latt - eq_latt
        f = refdata.ef[i] - np.dot(np.dot(latt_diff, hess), latt_diff.transpose()) - fitparam.ef
        deltaf.append(f[0, 0])
    
    deltaf = np.array(deltaf, dtype=float)
    
    return deltaf
    


# In[13]:


def writeout(fitted, ref, format_param, output):
    format_param.decouple_itarray(itarray=fitted, hess_size=ref.size)
    hess = format_param.restore_hess_mx(hess_size=ref.size)
    eigs = np.linalg.eig(hess)
    
    output.write('%s\n' % 'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT')
    output.write('\n')
    output.write('%-18s%16.2f%8s\n' % ('TEMPERATURE =', ref.tempt, 'K'))
    output.write('%-18s%16.4f%8s\n' % ('HELMOLTZ FE =', format_param.ef, 'KJ/MOL'))
    output.write('\n')
    output.write('%s\n' % ('IRREDUCIBLE LATTICE PARAMETERS')) 
    for i in format_param.latt:
        output.write('%-10.4f' % (i))
        
    output.write('\n\n')
    output.write('%s\n' % ('HESSIAN'))
    for i in range(hess.shape[0]):
        for j in range(hess.shape[1]):
            output.write('%-16.6f' % hess[i, j])
        
        output.write('\n')
    
    output.write('\n')
    output.write('%s\n' % 'EIGENVALUES OF HESSIAN') 
    for i in range(len(eigs[0])):
        output.write('%-16.6f' % eigs[0][i])
        output.write('%-12s' % 'VECTOR = ')
        for j in range(ref.size):
            output.write('%16.6f' % eigs[1][i][0, j])
        
        output.write('\n')
    
    output.write('\n')
      


# In[18]:


# Main I/O function
inputdata = Inpdata()
inputdata.readinput()

ref = []
for t in inputdata.tlist:
    a_ref = Refdata(tempt=t)
    a_ref.read_data(inputfiles=inputdata.nlist)
    ref.append(a_ref)

wtout = open('QHA_fit.dat', "w")
for ref_t in ref:
    para_set = Fitparam(ref=ref_t)
    para_in = para_set.generate_itarray()
    fitted = least_squares(qha_tylor, para_in, args=(ref_t, para_set))
    writeout(fitted.x, ref_t, para_set, wtout)
    
wtout.close()

