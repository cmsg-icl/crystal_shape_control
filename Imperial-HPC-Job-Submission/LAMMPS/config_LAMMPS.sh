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
LAMMPS Job Submitter for Imperial HPC - Configuration

Installation date     : `date`
Version               : v2.0
IC-HPC script version : v1.3 
Batch system          : PBS

Configured by Spica-Vir, Mar.04, 23, ICL, spica.h.zhou@gmail.com
Based on IC-HPC script released by Spica-Vir, Mar.01, 23, ICL, spica.h.zhou@gmail.com

Special thanks to A. Arber, K. Tallat Kelpsa, G.Mallia and N.M.Harrison

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path.

    Default Option:
    ${HOME}/runLAMMPS/

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/runLAMMPS/
    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi

    source_dir=`dirname $0`
    if [[ ${source_dir} == ${SCRIPTDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: You cannot specify source directory as your working directory. 
    Your option:  ${SCRIPTDIR}

EOF
        exit
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
    Please specify the directory of LAMMPS exectuables, 
    or the command to load lammps modules

    Default Option:
    module load  lammps/19Mar2020

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load  lammps/19Mar2020'
    fi

    if [[ ! -d ${EXEDIR} && (${EXEDIR} != *'module load'*) ]]; then
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
}

function set_mpi {
    cat << EOF
================================================================================
    Please specify the directory of MPI executables or mpi modules

    Default Option
    module load mpi/intel-2019 intel-suite/2019.4

EOF
    
    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
        MPIDIR='module load mpi/intel-2019 intel-suite/2019.4'
    fi

    if [[ ! -d ${EXEDIR} && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: ${MPIDIR}

EOF
        exit
    fi

    if [[ ${MPIDIR} == *'module load'* ]]; then
        ${MPIDIR} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: ${MPIDIR}

EOF
            exit
        fi
    fi
}

function copy_scripts {
    mkdir -p ${SCRIPTDIR}
    cp ${CTRLDIR}/settings_template ${SCRIPTDIR}/settings

    cat << EOF
================================================================================
    modified scripts at ${SCRIPTDIR}/
EOF
}

# Configure settings file

function set_settings {

    # Values for keywords
    SETFILE=${SCRIPTDIR}/settings
    sed -i "/SUBMISSION_EXT/a .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/N_THREAD/a 1" ${SETFILE}
    sed -i "/NGPU_PER_NODE/a 0" ${SETFILE}
    sed -i "/GPU_TYPE/a RTX6000" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a nodir" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a ${MPIDIR}" ${SETFILE}

    # Executable tabel

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
    sed -i "${LINE_EXE}a\slmp                            lmp -in [job].in –pk omp       Serial lammps" ${SETFILE}
    sed -i "${LINE_EXE}a\plmp-gpu   mpiexec              lmp_gpu -in [job].in           Parallel lammps with GPU acceleration" ${SETFILE}
    sed -i "${LINE_EXE}a\plmp       mpiexec              lmp_mpi -in [job].in -sf intel Parallel lammps" ${SETFILE}

    # # Input file table - calculation performed in current directory

    # LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    # LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
    # sed -i "${LINE_PRE}a\[job].in             *                    LAMMPS main input file" ${SETFILE}
    # sed -i "${LINE_EXT}a\[job].data           *                    Geometry data file" ${SETFILE}
    # sed -i "${LINE_EXT}a\[job].in.settings    *                    Atom, bond, angle... parameters file" ${SETFILE}
    # sed -i "${LINE_EXT}a\[job].in.init        *                    General setup file, for moltemplate" ${SETFILE}

    # # Reference file table - calculation performed in current directory

    # LINE_EXT=`grep -nw 'FILE_EXT' ${SETFILE}`
    # LINE_EXT=`echo "scale=0;${LINE_EXT%:*}+3" | bc`
    # sed -i "${LINE_EXT}a\[ref].restart        *                    Checkpoints to restart calculations" ${SETFILE}

    # # Post-processing file table

    # LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    # LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`
    # sed -i "${LINE_POST}a\*                    *.lammpstrj          lammps trajectory file" ${SETFILE}
    # sed -i "${LINE_POST}a\*                    *.data*              data files" ${SETFILE}
    # sed -i "${LINE_POST}a\[job].dump/          *.dump*              dump files" ${SETFILE}
    # sed -i "${LINE_POST}a\[job].restart/       *.restart*           restart files" ${SETFILE}
    # sed -i "${LINE_POST}a\[job].log            log.lammps           lammps output - no diagnosis information" ${SETFILE}

    # Job submission file template - should be placed at the end of file

    cat << EOF >> ${SETFILE}
-----------------------------------------------------------------------------------
#!/bin/bash  --login
#PBS -N \${V_JOBNAME}
#PBS -l select=\${V_ND}:ncpus=\${V_NCPU}:mem=\${V_MEM}:mpiprocs=\${V_PROC}:ompthreads=\${V_TRED}\${V_NGPU}\${V_TGPU}:avx2=true
#PBS -l walltime=\${V_TWT}

echo "PBS Job Report"
echo "--------------------------------------------"
echo "  Start Date : \$(date)"
echo "  PBS Job ID : \${PBS_JOBID}"
echo "  Status"
qstat -f \${PBS_JOBID}
echo "--------------------------------------------"
echo ""

# number of cores per node used
export NCORES=\${V_NCPU}
# number of processes
export NPROCESSES=\${V_TPROC}

# Make sure any symbolic links are resolved to absolute path
export PBS_O_WORKDIR=\$(readlink -f \${PBS_O_WORKDIR})

# Set the number of threads
export OMP_NUM_THREADS=\${V_TRED}

# to sync nodes
cd \${PBS_O_WORKDIR}

# start calculation: command added below by gen_sub
-----------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}.  

EOF
}

function set_commands {
    bgline=`grep -nw "# >>> LAMMPS job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish LAMMPS job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin LAMMPS job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Plmp='${CTRLDIR}/gen_sub -x plmp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Slmp='${CTRLDIR}/gen_sub -x slmp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xlmp='${CTRLDIR}/gen_sub -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETlmp='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPlmp='source $(dirname $0)/run_help; print_ALIAS_HOWTO_; print_GENSUB_HOWTO_'" >> ${HOME}/.bashrc
    # echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    # echo "chmod 777 ${SCRIPTDIR}/run_exec" >> ${HOME}/.bashrc
    # echo "chmod 777 ${SCRIPTDIR}/post_proc" >> ${HOME}/.bashrc 
    echo "# <<< finish LAMMPS job submitter settings <<<" >> ${HOME}/.bashrc

    source $(dirname $0)/run_help; print_ALIAS_HOWTO_
}

# Main I/O function
## Disambiguation : Here is a historical problem
## Variables and functions with 'script' in configure script refer to the user's local settings file and its directory
## In the current implementation, ${SCRIPTDIR} only has 1 file, i.e., user-defined settings file
## Executable scripts are now centralized and shared in ${CTRLDIR}
## For executable scripts, ${SCRIPTDIR} refer to their own directory. ${SETTINGS} refers to local settings file. 
CTRLDIR=$(dirname $0)/../
welcome_msg
get_scriptdir
copy_scripts
set_exe
set_mpi
set_settings
set_commands