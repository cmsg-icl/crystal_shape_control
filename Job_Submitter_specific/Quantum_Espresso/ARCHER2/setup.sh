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
Quantum Espresso job submitter for ARCHER2 - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1
Supported job scheduler:    SLURM

By Spica-Vir, Jan 10, 23, ICL, spica.h.zhou@gmail.com

EOF
}

function get_scriptdir {
    TMPSCRIPTDIR=${HOME#*/}
    TMPSCRIPTDIR="/work/${TMPSCRIPTDIR#*/}/runQE"
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${TMPSCRIPTDIR}):

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${TMPSCRIPTDIR}
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
            rm -rf ${SCRIPTDIR}
        fi
    fi
}

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of Quantum Espresso exectuables, 
    or the command to load QE modules (by default module load  quantum_espresso):

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load quantum_espresso'
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
    SETFILE=${SCRIPTDIR}/settings
    sed -i "/SUBMISSION_EXT/a\.slurm" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a\128" ${SETFILE}
    sed -i "/N_THREAD/a 8" ${SETFILE}
    sed -i "/BUDGET_CODE/a\ ${BUDGET_CODE}" ${SETFILE}
    sed -i "/QOS/a\standard" ${SETFILE}
    sed -i "/PARTITION/a\standard" ${SETFILE}
    sed -i "/TIME_OUT/a\3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\ "${JOBTMPDIR}"" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}

# Setup default file format tables
    ## Mandatory input
    LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+4" | bc`
    sed -i "${LINE_EXT}i[jobname].pwi   [jobname].pwi     Input for pw.x  PW-SCF" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].cpi   [jobname].cpi     Input for cp.x  CPMD" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].phi   [jobname].phi     Input for ph.x  DFPT" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].hpi   [jobname].hpi     Input for hp.x  DFT+U" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].epwi  [jobname].epwi    Input for epw.x Electron-Phonon Wannier" ${SETFILE}
    sed -i "${LINE_EXT}i[jobname].kcwi  [jobname].kcwi    Input for kcw.x Spectra" ${SETFILE}

    ## Optional input
    LINE_EXT=`grep -nw 'FILE_EXT' ${SETFILE}`
    LINE_EXT=`echo "scale=0;${LINE_EXT%:*}+4" | bc`
    ## No Optional input file

    ## Output
    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+4" | bc`
    sed -i "${LINE_POST}i[jobname].pwo          [jobname].pwo        Output for pw.x  PW-SCF" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].cpo          [jobname].cpo        Output for cp.x  CPMD" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].pho          [jobname].pho        Output for ph.x  DFPT" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].hpo          [jobname].hpo        Output for hp.x  DFT+U" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].epwo         [jobname].epwo       Output for epw.x Electron-Phonon Wannier" ${SETFILE}
    sed -i "${LINE_POST}i[jobname].kcwo         [jobname].kcwo       Output for kcw.x Spectra" ${SETFILE}

# Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------
#!/bin/bash
#SBATCH --nodes=\${V_ND}
#SBATCH --ntasks-per-node=\${V_PROC}
#SBATCH --cpus-per-task=\${V_TRED}
#SBATCH --time=\${V_WT}

# Replace [budget code] below with your full project code
#SBATCH --account=\${V_BUDGET}
#SBATCH --partition=\${V_PARTITION}
#SBATCH --qos=\${V_QOS}
#SBATCH --export=none

module load PrgEnv-aocc/8.0.0
module swap aocc/2.2.0.1 aocc/3.0.0
module load aocl

export FI_MR_CACHE_MAX_COUNT=0
export OMP_NUM_THREADS=\${V_TRED}

# start calculation: command added below by gen_sub
----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

EOF
}

function set_commands {
    bgline=`grep -nw "# >>> Quantum Espresso job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish Quantum Espresso job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> Quantum Espresso job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pqe='${SCRIPTDIR}/gen_sub'" >> ${HOME}/.bashrc
    echo "alias setpqe='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/run_exec" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/post_proc" >> ${HOME}/.bashrc 
    echo "# <<< finish Quantum Espresso job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    Pqe - executing parallel calculations

        Pqe -x EXE -nd ND -wt WT -in jobfile -ref [refname]

        EXE:      str, name of the executable
        ND:       int, number of nodes
        WT:       str, walltime, hh:mm format
        jobfile:  str, full name of the input file
        refname:  str, optional, name of the previous / reference job

    Multiple inputs

        Pqe -x EXE -in jobfile1 -ref reffile1 -x EXE -in jobfile2 -ref reffile2 -nd ND -wt WT

    The number of -x -in and -ref (if any) flags should be the same.

    setcrys - print the file 'settings'
    
================================================================================
EOF
}

# Main I/O function
welcome_msg
get_scriptdir
copy_scripts
set_exe
get_budget_code
set_settings
set_commands
