#!/bin/bash

function welcome_msg {
    core_version=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_date=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_author=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_contact=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_acknolg=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_version=`grep 'QE7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_date=`grep 'QE7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_author=`grep 'QE7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_contact=`grep 'QE7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_acknolg=`grep 'QE7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
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
Quantum Espresso7 job submission script for Imperial HPC - Setting up

Job submission script installed date : `date`
Batch system                         : PBS
Job submission script version        : ${code_version} (${code_date})
Job submission script author         : ${code_author} (${code_contact})
Core script version                  : ${core_version} (${core_date})
Job submission script author         : ${core_author} (${core_contact})

${code_acknolg}
${core_acknolg}

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path.

    Default Option
    ${HOME}/etc/runQE7/):

EOF

    read -p " " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/etc/runQE7
    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi
    
    SCRIPTDIR=`realpath $(echo ${SCRIPTDIR}) 2>&1 | sed -r 's/.*\:(.*)\:.*/\1/' | sed 's/[[:space:]]//g'` # Ignore errors
    source_dir=`realpath $(dirname $0)`
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
    Warning: Directory exists - current folder will be removed.

EOF
            rm -r ${SCRIPTDIR}
        fi
    fi
}

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of Quantum Espresso7 exectuables, 
    or the command to load QE7 modules

    Default Option
    Quantum Espresso 7.1 - mpi/omp

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load  /rds/general/user/hz1420/home/apps/QE-7.1/share/module_qe'
    fi

    if [[ ! -d ${EXEDIR} && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: ${EXEDIR}

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
    Intel OneAPI 2022.1.2

EOF
    
    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
	    export MODULEPATH="/rds/general/user/hz1420/home/apps/IntelOneAPI_v2022.1.2/modulefiles:${MODULEPATH}"
        MPIDIR='module load mkl/latest mpi/latest'
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
    Moving and modifying scripts at ${SCRIPTDIR}/
EOF
}

# Configure settings file

function set_settings {
    SETFILE=${SCRIPTDIR}/settings

    # Values for keywords
    sed -i "/SUBMISSION_EXT/a\ .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a\ 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a\ 100" ${SETFILE}
    sed -i "/NTHREAD_PER_PROC/a\ 1" ${SETFILE}
    sed -i "/NGPU_PER_NODE/a\ 0" ${SETFILE}
    sed -i "/GPU_TYPE/a\ RTX6000" ${SETFILE}
    sed -i "/TIME_OUT/a\ 3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\ nodir" ${SETFILE}
    sed -i "/EXEDIR/a\ ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}

    # Executable table

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
    sed -i "${LINE_EXE}a\pp         mpiexec                                                      pp.x < [job].in                                              Parallel data postprocessing" ${SETFILE}
    sed -i "${LINE_EXE}a\cp         mpiexec                                                      cp.x < [job].in                                              Parallel Car-Parrinello MD" ${SETFILE}
    sed -i "${LINE_EXE}a\ph         mpiexec                                                      ph.x < [job].in                                              Parallel Phonon (DFPT) calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pw         mpiexec                                                      pw.x < [job].in                                              Parallel PWscf calculation" ${SETFILE}

    # Input file table

	# LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    # LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
    # sed -i "${LINE_PRE}a\[jobname].gin        [jobname].gin        GULP input file" ${SETFILE}

    
    # Reference file table

	# LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    # LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`
    # sed -i "${LINE_REF}a\[refname].something  something            Some reference files" ${SETFILE}
    
    # Post-processing file table

    # LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    # LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`
    
    # sed -i "${LINE_POST}a\*                    *.inp                Force field coefficient file LAMMPS format" ${SETFILE}
    # sed -i "${LINE_POST}a\*                    *.lmp                Geometry file LAMMPS format" ${SETFILE}
    # sed -i "${LINE_POST}a\*                    *.xyz                Geometry file xyz format" ${SETFILE}

    # Job submission file template

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
export OMP_PLACES=cores

# to sync nodes
cd \${PBS_O_WORKDIR}

# Set temporary directory
export ESPRESSO_TMPDIR=\$(pwd)/\${V_JOBNAME}.save

# start calculation: command added below by gen_sub
-----------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 

EOF
}

# Configure user alias

function set_commands {
    bgline=`grep -nw "# >>> begin QE7 job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish QE7 job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin QE7 job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias PWqe7='${CTRLDIR}/gen_sub -x pw -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias PHqe7='${CTRLDIR}/gen_sub -x ph -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias CPqe7='${CTRLDIR}/gen_sub -x cp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias PPqe7='${CTRLDIR}/gen_sub -x pp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xqe7='${CTRLDIR}/gen_sub -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETqe7='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPqe7='bash ${CONFIGDIR}/run_help gensub'" >> ${HOME}/.bashrc
    echo "# <<< finish QE7 job submitter settings <<<" >> ${HOME}/.bashrc

    bash ${CONFIGDIR}/run_help
}

# Main I/O function
## Disambiguation : Here is a historical problem
## Variables and functions with 'script' in configure script refer to the user's local settings file and its directory
## In the current implementation, ${SCRIPTDIR} only has 1 file, i.e., user-defined settings file
## Executable scripts are now centralized and shared in ${CTRLDIR}
## For executable scripts, ${SCRIPTDIR} refer to their own directory. ${SETTINGS} refers to local settings file. 
CONFIGDIR=`realpath $(dirname $0)`
CTRLDIR=`realpath ${CONFIGDIR}/../`

welcome_msg
get_scriptdir
copy_scripts
set_exe
set_mpi
set_settings
set_commands
