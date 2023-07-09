#!/bin/bash

function welcome_msg {
    core_version=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_date=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'` 
    core_author=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_contact=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_acknolg=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_version=`grep 'Quantum-Espresso7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_date=`grep 'Quantum-Espresso7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_author=`grep 'Quantum-Espresso7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_contact=`grep 'Quantum-Espresso7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_acknolg=`grep 'Quantum-Espresso7' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
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
Quantum-Espresso7 job submission script for ARCHER2 - Setting up

Job submission script installed date : `date`
Batch system                         : SLURM
Job submission script version        : ${code_version} (${code_date})
Job submission script author         : ${code_author} (${code_contact})
Core script version                  : ${core_version} (${core_date})
Core script author                   : ${core_author} (${core_contact})

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
    ${WORK}/etc/runQE7

EOF

    read -p " " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${WORK}/etc/runQE7
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
    Warning: Directory exists - currnet folder will be removed.

EOF
            rm -r ${SCRIPTDIR}
        fi
    fi
}

function get_budget_code {
    cat << EOF
================================================================================
    Please specify your budget code:

EOF

    read -p " " BUDGET_CODE
    BUDGET_CODE=`echo ${BUDGET_CODE}`

    if [[ -z ${BUDGET_CODE} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Budget code must be specified. Exiting current job.

EOF
        exit
    fi
}

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of CRYSTAL exectuables,
    or the command to load CRYSTAL modules

    Default Option
    module load quantum_espresso/7.1

EOF

    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load quantum_espresso/7.1'
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
    module load PrgEnv-gnu/8.3.3 gcc/11.2.0 cray-mpich/8.1.23 cray-libsci/22.12.1.1

EOF

    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
        MPIDIR='module load PrgEnv-gnu/8.3.3 gcc/11.2.0 cray-mpich/8.1.23 cray-libsci/22.12.1.1'
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
    sed -i "/SUBMISSION_EXT/a\.slurm" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a\128" ${SETFILE}
    sed -i "/NTHREAD_PER_PROC/a\ 1" ${SETFILE}
    sed -i "/BUDGET_CODE/a\ ${BUDGET_CODE}" ${SETFILE}
    sed -i "/QOS/a\standard" ${SETFILE}
    sed -i "/PARTITION/a\standard" ${SETFILE}
    sed -i "/TIME_OUT/a\3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\ nodir" ${SETFILE}
    sed -i "/EXEDIR/a\ ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}

    # Executable table

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
    sed -i "${LINE_EXE}a\pp         srun --hint=nomultithread --distribution=block:block         pp.x < [job].in                                              Parallel data postprocessing" ${SETFILE}
    sed -i "${LINE_EXE}a\cp         srun --hint=nomultithread --distribution=block:block         cp.x < [job].in                                              Parallel Car-Parrinello MD" ${SETFILE}
    sed -i "${LINE_EXE}a\ph         srun --hint=nomultithread --distribution=block:block         ph.x < [job].in                                              Parallel Phonon (DFPT) calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pw         srun --hint=nomultithread --distribution=block:block         pw.x < [job].in                                              Parallel PWscf calculation" ${SETFILE}

    # Use QE's built-in temporary file management commands
    # # Input file table

    # LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    # LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
    # sed -i "${LINE_PRE}a\[jobname].POINTCHG   POINTCHG.INP         Dummy atoms with 0 mass and given charge" ${SETFILE}

    # # Reference file table

    # LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    # LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`
    # sed -i "${LINE_REF}a\[refname].f31        fort.32              Derivative of density matrix" ${SETFILE}

    # # Post-processing file table

    # LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    # LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`

    # sed -i "${LINE_POST}a\[jobname].POTC       POTC.DAT             Electrostatic potential and derivatives" ${SETFILE}

    # Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------
#!/bin/bash
#SBATCH --nodes=\${V_ND}
#SBATCH --ntasks-per-node=\${V_PROC}
#SBATCH --cpus-per-task=\${V_TREAD}
#SBATCH --time=\${V_TWT}

# Replace [budget code] below with your full project code
#SBATCH --account=\${V_BUDGET}
#SBATCH --partition=\${V_PARTITION}
#SBATCH --qos=\${V_QOS}
#SBATCH --export=none

echo "============================================"
echo "SLURM Job Report"
echo "--------------------------------------------"
echo "  Start Date : \$(date)"
echo "  SLURM Job ID : \${SLURM_JOB_ID}"
echo "  Status"
squeue -j \${SLURM_JOB_ID} 2>&1
echo "============================================"
echo ""

# Address the memory leak
export FI_MR_CACHE_MAX_COUNT=0

# Set number of threads and OMP level
export OMP_NUM_THREADS=\${V_TRED}
export OMP_PLACES=cores

# Set temporary directory
export ESPRESSO_TMPDIR=\$(pwd)/\${V_JOBNAME}.save

# start calculation: command added below by gen_sub
----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}.

EOF
}

# Configure user alias

function set_commands {
    bgline=`grep -nw "# >>> begin Quantum-Esppresso 7 job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish Quantum-Esppresso 7 job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin Quantum-Esppresso 7 job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias PWqe7='${CTRLDIR}/gen_sub -x pw -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias PHqe7='${CTRLDIR}/gen_sub -x ph -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias CPqe7='${CTRLDIR}/gen_sub -x cp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias PPqe7='${CTRLDIR}/gen_sub -x pp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xqe7='${CTRLDIR}/gen_sub -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETqe7='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPqe7='source ${CONFIGDIR}/run_help gensub" >> ${HOME}/.bashrc
    echo "chmod -R 'u+r+w+x' ${CTRLDIR}" >> ${HOME}/.bashrc
    echo "chmod 'u+r+w+x' ${CONFIGDIR}/run_help" >> ${HOME}/.bashrc
    echo "# <<< finish Quantum-Esppresso 7 job submitter settings <<<" >> ${HOME}/.bashrc

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
get_budget_code
set_exe
set_mpi
set_settings
set_commands
