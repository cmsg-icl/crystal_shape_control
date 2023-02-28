#!/bin/bash

function welcome_msg {
#--# BEGIN_USER
#--# Code name
#--# Version number: update config file: change the minor version number; 
#--#                 update general files: change the major version number and reset minor version number
#--# Author, date, contact
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
General job submitter, GROMACS version, for Imperial HPC - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1
Supported job scheduler:    PBS

By Spica-Vir, Jun.28, 22, ICL, spica.h.zhou@gmail.com

Special thanks to G.Mallia, N.M.Harrison, K. Tallat Kelpsa

EOF
}
#--# END_USER

function get_scriptdir {
#--# BEGIN_USER: Default path to script directory
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${HOME}/runGROMACS/):

EOF
#--# END_USER

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

#--# BEGIN_USER: Default path to script directory
    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/runGROMACS/
    fi
#--# END_USER

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
#--# BEGIN_USER: Default path to exe directory / module load command
    cat << EOF
================================================================================
    Please specify the directory of GROMACS exectuables, 
    or the command to load GROMACS modules (by default module load  gromacs/2021.3-mpi):

EOF
#--# END_USER
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

#--# BEGIN_USER: Default path to exe directory / module load command
    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load  gromacs/2021.3-mpi'
    fi
#--# END_USER

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

#--# BEGIN_USER: Default exe name (+ options)
    cat << EOF
================================================================================
    Please specify the GROMACS exectuable name and options (by default name: gmx_mpi, option: mdrun -s):

EOF
#--# END_USER
    
    read -p "    Exectuable name:    " EXENAME
    EXENAME=`echo ${EXENAME}`

#--# BEGIN_USER: Default exe name
    if [[ -z ${EXENAME} ]]; then
        EXENAME='gmx_mpi'
    fi
#--# END_USER

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

    read -p "    Exectuable options:    " EXEOPT
    EXEOPT=`echo ${EXEOPT}`

#--# BEGIN_USER: Default option. If no option is needed, EXEOPT=''
    if [[ -z ${EXEOPT} ]]; then
        EXEOPT='mdrun -s'
    fi
#--# END_USER
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
#--# BEGIN_USER: Depends on user's habit. Can be modified later in settings file.
    sed -i "/NCPU_PER_NODE/a 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/N_THREAD/a 1" ${SETFILE}
    sed -i "/NGPU_PER_NODE/a 0" ${SETFILE}
    sed -i "/GPU_TYPE/a RTX6000" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
#--# END_USER
    sed -i "/JOB_TMPDIR/a \/rds\/general\/ephemeral\/user\/${USER}\/ephemeral" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PARALLEL/a ${EXENAME}" ${SETFILE}
    sed -i "/EXE_OPTIONS/a ${EXEOPT}" ${SETFILE}

# Setup default file format tables
	LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+4" | bc`

#--# BEGIN_USER: Definition of mandatory input files
    sed -i "${LINE_PRE}i[jobname].tpr          [jobname].tpr          GROMACS portable binary run input file" ${SETFILE}
#--# END_USER

	LINE_EXT=`grep -nw 'FILE_EXT' ${SETFILE}`
    LINE_EXT=`echo "scale=0;${LINE_EXT%:*}+4" | bc`

#--# BEGIN_USER: Definition of optional input files
    # sed -i "${LINE_EXT}i[jobname].anything   [jobname].anything     Anything you like" ${SETFILE}
#--# END_USER

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+4" | bc`

#--# BEGIN_USER: Definition of output files
    sed -i "${LINE_POST}i[jobname].CheckPoint\/  *.cpt                Checkpoint files" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].gro          *.gro                Gromacs geometry file" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].trr          *.trr                Trajectory file" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].trj          *.trj                Trajectory file" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].log          *.log                MD output file" ${SETFILE}
#--# END_USER

# Job submission file template - should be placed at the end of file

#--# BEGIN_USER: Definition of output files
#--# Code-specific settings. Should be especially careful when using self-compiled codes. e.g., Environmental variables, modules
    cat << EOF >> ${SETFILE}
-----------------------------------------------------------------------------------
#!/bin/bash  --login
#PBS -N \${V_PBSJOBNAME}
#PBS -l select=\${V_ND}:ncpus=\${V_NCPU}:mem=\${V_MEM}:mpiprocs=\${V_PROC}:ompthreads=\${V_TRED}\${V_NGPU}\${V_TGPU}:avx2=true
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

# start calculation: command added below by gen_sub
-----------------------------------------------------------------------------------

EOF
#--# END_USER
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

EOF
}

function set_commands {
#--# BEGIN_USER: Config ~/.bashrc change the code name
    bgline=`grep -nw "# >>> GROMACS job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish GROMACS job submitter settings <<<" ${HOME}/.bashrc`
#--# END_USER

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi
#--# BEGIN_USER: change the code name and define a good name for alias. 'Pgmx' and 'setgmx' in this example
    echo "# >>> GROMACS job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pgmx='${SCRIPTDIR}/gen_sub'" >> ${HOME}/.bashrc
    echo "alias setgmx='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/run_exec" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/post_proc" >> ${HOME}/.bashrc 
    echo "# <<< finish GROMACS job submitter settings <<<" >> ${HOME}/.bashrc
#--# END_USER

    source ${HOME}/.bashrc

#--# BEGIN_USER: update the instructions
    cat << EOF
================================================================================
    User defined commands set, including: 

    Pgmx - executing parallel GROMACS calculations

        Pgmx -in <input> -wt <walltime> -nd <node> -- -<other options>

                 -in:  str, main input file, must have the required extensions
                 -wt:  str, walltime, hh:mm format
                 -nd:  int, number of nodes
                  --:  str, optional, separator
    -<other options>:  str, optional, other command-line options behind 
                       this label

        the sequence of -in, -wt, -nd can be changed. Other options should
        always be placed at the end. 

    setgmx - print the file 'settings'
    
================================================================================
EOF
#--# END_USER
}

# Main I/O function
welcome_msg
get_scriptdir
copy_scripts
set_exe
set_settings
set_commands
