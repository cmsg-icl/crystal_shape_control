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
CRYSTAL17 job submitter for ARCHER2 - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1
Supported job scheduler:    SLURM

By Spica-Vir, Mar. 18-22, ICL, spica.h.zhou@gmail.com

Developed based on Dr G.Mallia's scripts on Imperial cluster
Special thanks to G.Mallia & N.M.Harrison

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${HOME}/runCRYSTAL/):

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

	if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/runCRYSTAL/
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
        cp runcryP           ${SCRIPTDIR}/runcryP
        cp runpropP          ${SCRIPTDIR}/runpropP
        cp settings_template ${SCRIPTDIR}/settings
        cp post_processing   ${SCRIPTDIR}/post_processing
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
    sed -i "/SUBMISSION_EXT/a .slurm" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 128" ${SETFILE}
    sed -i "/BUDGET_CODE/a ${BUDGET_CODE}" ${SETFILE}
    sed -i "/QOS/a standard" ${SETFILE}
    sed -i "/PARTITION/a standard" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/CRYSTAL_SCRIPT/a Pcry_slurm" ${SETFILE}
    sed -i "/PROPERTIES_SCRIPT/a Pprop_slurm" ${SETFILE}
    sed -i "/POST_PROCESSING_SCRIPT/a post_proc_slurm" ${SETFILE}
    JOBTMPDIR=/work${HOME:5}
    sed -i "/JOB_TMPDIR/a "${JOBTMPDIR}"" ${SETFILE}

# Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------
#!/bin/bash
#SBATCH --nodes=\${V_ND}
#SBATCH --ntasks-per-node=\${V_NCPU}
#SBATCH --cpus-per-task=1
#SBATCH --time=\${V_WT}

# Replace [budget code] below with your full project code
#SBATCH --account=\${V_BUDGET}
#SBATCH --partition=\${V_PARTITION}
#SBATCH --qos=\${V_QOS}
#SBATCH --export=none

module load epcc-job-env
module load other-software
module load crystal

# Address the memory leak
export FI_MR_CACHE_MAX_COUNT=0 

# Run calculations
timeout \${V_TOUT} \${V_SCRIPTDIR}/\${V_SCRIPT} \${V_JOBNAME} \${V_REFNAME}
\${V_SCRIPTDIR}/\${V_POSCRIPT} \${V_JOBTYPE} \${V_JOBNAME}
----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

EOF
}

function set_commands {
    sed -i '/CRYSTAL job submitter settings/d' ${HOME}/.bashrc
    sed -i '/Pcry=/d' ${HOME}/.bashrc
    sed -i '/Pprop=/d' ${HOME}/.bashrc
    sed -i '/setfile=/d' ${HOME}/.bashrc

    echo "# >>> CRYSTAL job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcry='${SCRIPTDIR}/gen_sub crys'" >> ${HOME}/.bashrc
    echo "alias Pprop='${SCRIPTDIR}/gen_sub prop'" >> ${HOME}/.bashrc
    echo "alias setfile='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "# <<< finish CRYSTAL job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    Pcry - executing parallel crystal calculations (Pcrystal and MPP)

        Pcry ND WT jobname [refname]

        ND:       int, number of nodes
        WT:       str, walltime, hh:mm format
        jobname:  str, name of input .d12 file
        refname:  str, optional, name of the previous job

    Pprop - executing parallel properties calculations (Pproperties)

        Pprop ND WT jobname SCFname

        ND:       int, number of nodes
        WT:       str, walltime, hh:mm format
        jobname:  str, name of input .d3 file
        SCFname:  str, optional, name of the previous 'crystal' job

    setfile - print the file 'settings'
	
================================================================================
EOF
}

# Main I/O function
welcome_msg
get_scriptdir
copy_scripts
get_exedir
set_settings
set_commands
