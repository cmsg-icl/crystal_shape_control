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
LAMMPS job submitter for Imperial HPC - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1.1
Supported job scheduler:    PBS

By Spica-Vir, Mar. 21-22, ICL, spica.h.zhou@gmail.com

Special thanks to G.Mallia, N.M.Harrison, A. Arber

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

function get_exedir {
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

function copy_scripts {
    curr_dir=`pwd`

    if [[ ${SCRIPTDIR} != ${curr_dir} ]]; then
        mkdir -p             ${SCRIPTDIR}
        cp gen_sub           ${SCRIPTDIR}/gen_sub
        cp runPlmp           ${SCRIPTDIR}/runPlmp
        cp settings_template ${SCRIPTDIR}/settings
        cp postlmp           ${SCRIPTDIR}/postlmp
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
    sed -i "/SUBMISSION_EXT/a .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/LMP_SCRIPT/a runPlmp" ${SETFILE}
    sed -i "/PROPERTIES_SCRIPT/a runpropP" ${SETFILE}
    sed -i "/POST_PROCESSING_SCRIPT/a postlmp" ${SETFILE}
    sed -i "/JOB_TMPDIR/a \/rds\/general\/ephemeral\/user\/${USER}\/ephemeral" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PLMP/a lmp_mpi" ${SETFILE}
    # sed -i "/EXE_LMP/a lmp" ${SETFILE}

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
timeout \${V_TOUT} \${V_SCRIPTDIR}/\${V_SCRIPT} \${V_JOBNAME_IN} \${V_REFNAME} -- \${V_OTHER}
\${V_SCRIPTDIR}/\${V_POSCRIPT} \${V_JOBNAME_IN} \${V_REFNAME}

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
    sed -i '/LAMMPS job submitter settings/d' ${HOME}/.bashrc
    sed -i '/Plmp=/d' ${HOME}/.bashrc
    sed -i '/setlmp=/d' ${HOME}/.bashrc

    echo "# >>> LAMMPS job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Plmp='${SCRIPTDIR}/gen_sub'" >> ${HOME}/.bashrc
	echo "chmod 777 ${SCRIPTDIR}/gen_sub" >> ${HOME}/.bashrc
    echo "alias setlmp='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "# <<< finish LAMMPS job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    Plmp - executing parallel LAMMPS calculations

        Plmp -in <input> -wt <walltime> -nd <node> -ref <restart> -- <other LAMMPS options>

         -in:  str, main input file, must include '.in'
         -wt:  str, walltime, hh:mm format
         -nd:  int, number of nodes
        -ref:  str, optional, restart file
          --:  str, optional, other LAMMPS options behind this label

        the sequence of -in, -wt, -nd, -ref can be changed. '--' should always
        be placed at the end. 

    setlmp - print the file 'settings'
	
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
