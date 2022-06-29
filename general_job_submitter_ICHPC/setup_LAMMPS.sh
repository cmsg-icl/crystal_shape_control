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
General job submitter, LAMMPS version, for Imperial HPC - Setting up

Job submitter installed at: `date`
Job submitter edition:      v2.0
Supported job scheduler:    PBS

By Spica-Vir, Jun.28, 22, ICL, spica.h.zhou@gmail.com

Special thanks to G.Mallia, N.M.Harrison, A. Arber, K. Tallat Kelpsa

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${HOME}/runLAMMPS/):

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/runLAMMPS/
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
    Please specify the directory of LAMMPS exectuables, 
    or the command to load lammps modules (by default module load  lammps/19Mar2020):

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load  lammps/19Mar2020'
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
}

    cat << EOF
================================================================================
    Please specify the LAMMPS exectuable name and options (by default lmp_mpi -in):

EOF
    
    read -p "    Exectuable name:    " EXENAME
    EXENAME=`echo ${EXENAME}`

    if [[ -z ${EXENAME} ]]; then
        EXENAME='lmp_mpi'
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

    read -p "    Exectuable options:    " EXEOPT
    EXEOPT=`echo ${EXEOPT}`
    if [[ -z ${EXEOPT} ]]; then
        EXEOPT='-in'
    fi
}

function copy_scripts {
    curr_dir=`pwd`

    if [[ ${SCRIPTDIR} != ${curr_dir} ]]; then
        mkdir -p             ${SCRIPTDIR}
        cp gen_sub           ${SCRIPTDIR}/gen_sub
        cp run_exec          ${SCRIPTDIR}/run_exec
        cp settings_LAMMPS   ${SCRIPTDIR}/settings
        cp post_proc         ${SCRIPTDIR}/post_proc
    else
        cp settings_LAMMPS settings
    fi

    cat << EOF
================================================================================
    modified scripts at ${SCRIPTDIR}/
EOF
}

function set_settings {
    SETFILE=${SCRIPTDIR}/settings
    sed -i "/SUBMISSION_EXT/a .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/N_THREAD/a 1" ${SETFILE}
    sed -i "/NGPU_PER_NODE/a 0" ${SETFILE}
    sed -i "/GPU_TYPE/a RTX6000" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/EXE_SCRIPT/a run_exec" ${SETFILE}
    sed -i "/POST_PROCESSING_SCRIPT/a post_proc" ${SETFILE}
    sed -i "/JOB_TMPDIR/a \/rds\/general\/ephemeral\/user\/${USER}\/ephemeral" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PARALLEL/a ${EXENAME}" ${SETFILE}
    sed -i "/EXE_OPTIONS/a ${EXEOPT}" ${SETFILE}

# Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
-----------------------------------------------------------------------------------
#!/bin/bash  --login
#PBS -N \${V_JOBNAME}
#PBS -l select=\${V_ND}:ncpus=\${V_NCPU}:mpiprocs=\${V_NCPU}:ompthreads=1:mem=\${V_MEM}
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

# Set the number of threads to 1
#   This prevents any system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1
# env (Uncomment this line to get all environmental variables)
echo "</qsub_standard_output>"

# to sync nodes
cd \${PBS_O_WORKDIR}
# MPI dependends on modules - for lammps/19Mar2020
# can be commended - dependents will be loaded when loading lammps/19Mar2020
module load  intel-suite/2019.4
module load  mpi/intel-2019

# start calculation
timeout \${V_TOUT} \${V_SCRIPTDIR}/\${V_SCRIPT} -in \${V_JOBNAME} -- \${V_OTHER}
\${V_SCRIPTDIR}/\${V_POSCRIPT} -in \${V_JOBNAME_IN}

###
if [[ -f ./\${V_JOBNAME}.run ]];then
chmod 755 ./\${V_JOBNAME}.run
./\${V_JOBNAME}.run
fi
-----------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

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

    echo "# >>> LAMMPS job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Plmp='${SCRIPTDIR}/gen_sub'" >> ${HOME}/.bashrc
    echo "alias setlmp='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/run_exec" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/post_proc" >> ${HOME}/.bashrc 
    echo "# <<< finish LAMMPS job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    Plmp - executing parallel LAMMPS calculations

        Plmp -in <input> -wt <walltime> -nd <node> -- -<other options>

                 -in:  str, main input file, must have the required extensions
                 -wt:  str, walltime, hh:mm format
                 -nd:  int, number of nodes
                  --:  str, optional, separator
    -<other options>:  str, optional, other command-line options behind 
                       this label

        the sequence of -in, -wt, -nd can be changed. Other options should
        always be placed at the end. 

    setlmp - print the file 'settings'
    
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
