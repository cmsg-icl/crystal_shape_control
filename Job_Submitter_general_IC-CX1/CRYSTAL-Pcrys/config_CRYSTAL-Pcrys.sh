#!/bin/bash

function welcome_msg {
    cat << EOF
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
    _   _   _   _______   _          ___        ___       _______    _______   
   | | | | | | |  _____| | |       / ___ \    / ___ \    / _   _ \  |  _____|  
   | | | | | | | |       | |      / /   \_\  / /   \ \  | / \ / \ | | |        
   | | | | | | | |____   | |     | |        | |     | | | | | | | | | |____    
   | | | | | | | |____|  | |     | |        | |     | | | | | | | | | |____|   
   | | | | | | | |       | |     | |     __ | |     | | | | | | | | | |        
   | \_/ \_/ | | |_____  | |_____ \ \___/ /  \ \___/ /  | | |_| | | | |_____   
    \__/\___/  |_______| |_______| \ ___ /    \ ___ /   |_|     |_| |_______|  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
General job submitter, CRYSTAL parallel crystal version, for Imperial HPC - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1
Supported job scheduler:    PBS

By Spica-Vir, Jul.03, 22, ICL, spica.h.zhou@gmail.com

Special thanks to G.Mallia and N.M.Harrison

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${HOME}/runCRYSTAL-Pcrys/):

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/runCRYSTAL-Pcrys/
    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi

    curr_dir=`pwd`
    if [[ ${curr_dir} == ${SCRIPTDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Warning: Current directory set as script directory. 

EOF
    else
        ls ${SCRIPTDIR} > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Warning: Directory exists - currnet folder will be removed.

EOF
            rm -r ${SCRIPTDIR}
        fi
    fi
}

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of crystal exectuable of CRYSTAL, 
    or the command to load CRYSTAL modules
    (by default /rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/bin/Linux-mpigfortran_MPP/Xeon___mpich__3.2.1):

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='/rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/bin/Linux-mpigfortran_MPP/Xeon___mpich__3.2.1'
    fi

    if [[ (! -s ${EXEDIR} || ! -e ${EXEDIR}) && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Exiting current job. 

EOF
        exit
    fi

    if [[ ${EXEDIR} == *'module load'* ]]; then
        ${EXEDIR} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
                    cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: ${EXEDIR}

EOF
            exit
        fi
    fi

    cat << EOF
================================================================================
    Please specify the crystal exectuable of CRYSTAL package (by default Pcrystal):

EOF
    
    read -p "    Exectuable name:    " EXENAME
    EXENAME=`echo ${EXENAME}`

    if [[ -z ${EXENAME} ]]; then
        EXENAME='Pcrystal'
    fi

    if [[ (! -s ${EXEDIR}/${EXENAME} || ! -e ${EXEDIR}/${EXENAME}) && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Executable does not exist. Exiting current job. 

EOF
        exit
    fi

    if [[ ${EXEDIR} == *'module load'* ]]; then
        ${EXEDIR} > /dev/null 2>&1
        ${EXENAME} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
                    cat << EOF
--------------------------------------------------------------------------------
    Error: Command specified is wrong. Check help messages of the loaded module: ${EXEDIR}

EOF
            exit
        fi
    fi

    # read -p "    Exectuable options:    " EXEOPT
    # EXEOPT=`echo ${EXEOPT}`
    # if [[ -z ${EXEOPT} ]]; then
    #     EXEOPT='-in'
    # fi
    EXEOPT=''
}

function copy_scripts {
    curr_dir=`pwd`

    if [[ ${SCRIPTDIR} != ${curr_dir} ]]; then
        mkdir -p             ${SCRIPTDIR}
        cp gen_sub           ${SCRIPTDIR}/gen_sub
        cp run_exec          ${SCRIPTDIR}/run_exec
        cp settings_template ${SCRIPTDIR}/settings
        cp post_proc         ${SCRIPTDIR}/post_proc
    else
        cp settings_template settings
    fi

    cat << EOF
================================================================================
    modified scripts at ${SCRIPTDIR}/
EOF
}

function set_settings {

# Setup default parameters
    SETFILE=${SCRIPTDIR}/settings
    sed -i "/SUBMISSION_EXT/a .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/N_THREAD/a 1" ${SETFILE}
    sed -i "/NGPU_PER_NODE/a 0" ${SETFILE}
    sed -i "/GPU_TYPE/a RTX6000" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a \/rds\/general\/ephemeral\/user\/${USER}\/ephemeral" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PARALLEL/a ${EXENAME}" ${SETFILE}
    sed -i "/EXE_OPTIONS/a ${EXEOPT}" ${SETFILE}

# Setup default file format tables
    LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+4" | bc`
    sed -i "${LINE_PRE}i[jobname].d12          [jobname].d12          CRYSTAL-Pcrys main input file" ${SETFILE}

    LINE_EXT=`grep -nw 'FILE_EXT' ${SETFILE}`
    LINE_EXT=`echo "scale=0;${LINE_EXT%:*}+4" | bc`
    sed -i "${LINE_EXT}i[jobname].gui          fort.34                Geometry input file" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].POINTCHG     POINTCHG.INP           Dummy atoms with 0 mass and given charge" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].f9           fort.20                Last step wavefunction - input" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].OPTINFO      OPTINFO.DAT            Optimisation restart data" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].FREQINFO     FREQINFO.DAT           Frequency restart data" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].BORN         BORN.DAT               Born tensor" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].TENS_RAMAN   TENS_RAMAN.DAT         Raman tensor" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].f13          fort.13                Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].f28          fort.28                Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].f81          fort.81                Wannier funcion restart data" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].EOSINFO      EOSINFO.DAT            QHA and equation of states information" ${SETFILE}
    sed -i "${LINE_EXT}i[pre_job].f32          fort.32                CPHF/KS restart data" ${SETFILE}

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+4" | bc`
    sed -i "${LINE_POST}i[jobname].ERROR        fort.87              Error report" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].gui          fort.34              Geometry, periodic" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].xyz          fort.33              Geometry, atom coordinates only" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].cif          GEOMETRY.CIF         Geometry, cif format (CIFPRT/CIFPRTSYM)" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].STRUC        STRUC.INCOOR         Geometry, STRUC.INCOOR format" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].FINDSYM      FINDSYM.DAT          Geometry, for FINDSYM" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].cif          GEOMETRY.CIF         Geometry, cif format (CIFPRT/CIFPRTSYM)" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].GAUSSIAN     GAUSSIAN.DAT         Geometry, for Gaussian98/03" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f9           fort.9               Last step wavefunction - output" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f98          fort.98              Formatted wavefunction" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].PPAN         PPAN.DAT             Mulliken population" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].SCFLOG       SCFOUT.LOG           SCF output per step" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].OPTINFO      OPTINFO.DAT          Optimisation restart data" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].HESSOPT      HESSOPT.DAT          Hessian matrix per optimisation step" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].optstory/    opt*                 Optimised geometry per step " ${SETFILE}
    sed -i "${LINE_POST}i[jobname].FREQINFO     FREQINFO.DAT         Frequency restart data" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f13          fort.13              Binary reducible density matrix  " ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f28          fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f81          fort.80              Wannier funcion restart data" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].scanmode/    SCAN*                Displaced .gui along scanned mode" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f25          fort.25              Phonon bands Crgra2006 format" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].PHONBANDS    PHONBANDS.DAT        Phonon bands xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].IRDIEL       IRDIEL.DAT           IR dielectric function" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].IRREFR       IRREFR.DAT           IR refractive index" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].IRSPEC       IRSPEC.DAT           IR absorbance and reflectance" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].BORN         BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].RAMSPEC      RAMSPEC.DAT          Raman spectra" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].TENS_RAMAN   TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].EOSINFO      EOSINFO.DAT          QHA and equation of states information" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].f32          fort.31              CPHF/KS restart data" ${SETFILE}

# Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
-----------------------------------------------------------------------------------
#!/bin/bash  --login
#PBS -N \${V_PBSJOBNAME}
#PBS -l select=\${V_ND}:ncpus=\${V_NCPU}:mem=\${V_MEM}:mpiprocs=\${V_PROC}:ompthreads=\${V_TRED}\${V_NGPU}\${V_TGPU}
#PBS -l walltime=\${V_WT}

echo "<qsub_standard_output>"
date
echo "<qstat -f \${PBS_JOBID}>"
qstat -f \${PBS_JOBID}
echo "</qstat -f \${PBS_JOBID}>"

# number of cores per node used
export NCORES=\${V_NCPU}
# number of processes
export NPROCESSES=\${V_NP}

# Make sure any symbolic links are resolved to absolute path
export PBS_O_WORKDIR=\$(readlink -f \${PBS_O_WORKDIR})

# Set the number of threads
export OMP_NUM_THREADS=\${V_TRED}
# env (Uncomment this line to get all environmental variables)
echo "</qsub_standard_output>"

# to sync nodes
cd \${PBS_O_WORKDIR}

# Specify any other important dependencies below
export MODULEPATH=\$MODULEPATH:\${HOME}/../../gmallia/home/CRYSTAL17_cx1/v2.2gnu/modules
echo "MODULEPATH= "\${MODULEPATH}
echo 'Initial list of module loaded'
module load  mpich/3.2.1
# start calculation
-----------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

EOF
}

function set_commands {
    bgline=`grep -nw "# >>> CRYSTAL-Pcrys job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish CRYSTAL-Pcrys job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> CRYSTAL-Pcrys job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcrys='${SCRIPTDIR}/gen_sub'" >> ${HOME}/.bashrc
    echo "alias setpcrys='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/run_exec" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/post_proc" >> ${HOME}/.bashrc 
    echo "# <<< finish CRYSTAL-Pcrys job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    Pcrys - executing parallel crystall calculations of CRYSTAL

        Pcrys -in <input> -wt <walltime> -nd <node> -- -<other options>

                 -in:  str, main input file, must have the required extensions
                 -wt:  str, walltime, hh:mm format
                 -nd:  int, number of nodes
                  --:  str, optional, separator
    -<other options>:  str, optional, other command-line options behind 
                       this label

        the sequence of -in, -wt, -nd can be changed. Other options should
        always be placed at the end. 

    setpcrys - print the file 'settings'
    
================================================================================
EOF
}

# Main I/O function
welcome_msg
get_scriptdir
copy_scripts
set_exe
set_settings
set_commands
