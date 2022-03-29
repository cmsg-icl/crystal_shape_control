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
CRYSTAL17 job submitter for Imperial HPC - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.3
Supported job scheduler:    PBS

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

function get_exedir {
    cat << EOF
================================================================================
    Please specify the directory of CRYSTAL exectuables (by default cry17gnu v2.2):

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR=/rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/bin/Linux-mpigfortran_MPP/Xeon___mpich__3.2.1
    fi

    if [[ ! -s ${EXEDIR} || ! -e ${EXEDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory does not exist. Exiting current job. 

EOF
        exit
    fi
}

function copy_scripts {
    curr_dir=`pwd`

    if [[ ${SCRIPTDIR} != ${curr_dir} ]]; then
        mkdir -p             ${SCRIPTDIR}
        cp gen_sub_crys      ${SCRIPTDIR}/gen_sub_crys
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
    sed -i "/SUBMISSION_EXT/a .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a 48" ${SETFILE}
    sed -i "/MEM_PER_NODE/a 50" ${SETFILE}
    sed -i "/TIME_OUT/a 3" ${SETFILE}
    sed -i "/CRYSTAL_SCRIPT/a runcryP" ${SETFILE}
    sed -i "/PROPERTIES_SCRIPT/a runpropP" ${SETFILE}
    sed -i "/POST_PROCESSING_SCRIPT/a post_processing" ${SETFILE}
    sed -i "/JOB_TMPDIR/a \/rds\/general\/ephemeral\/user\/${USER}\/ephemeral" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PCRYSTAL/a Pcrystal" ${SETFILE}
    sed -i "/EXE_MPP/a MPPcrystal" ${SETFILE}
    sed -i "/EXE_PPROPERTIES/a Pproperties" ${SETFILE}

# Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------
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
env
echo "</qsub_standard_output>"

#to sync nodes
cd \${PBS_O_WORKDIR}
touch wood
export MODULEPATH=\$MODULEPATH:\${HOME}/../../gmallia/home/CRYSTAL17_cx1/v2.2gnu/modules
echo "MODULEPATH= "\${MODULEPATH}
echo Initial list of module loaded
module list -l
module load  mpich/3.2.1

# start calculation
timeout \${V_TOUT} \${V_SCRIPTDIR}/\${V_SCRIPT} \${V_JOBNAME} \${V_REFNAME}
\${V_SCRIPTDIR}/\${V_POSCRIPT} \${V_JOBTYPE} \${V_JOBNAME}

###
if [[ -f ./\${V_JOBNAME}.run ]];then
chmod 755 ./\${V_JOBNAME}.run
./\${V_JOBNAME}.run
fi
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
    sed -i '/setcrys=/d' ${HOME}/.bashrc
    sed -i '/gen_sub_crys/d' ${HOME}/.bashrc
    sed -i '/runcryP/d' ${HOME}/.bashrc
    sed -i '/runpropP/d' ${HOME}/.bashrc
    sed -i '/post_processing/d' ${HOME}/.bashrc

    echo "# >>> CRYSTAL job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcry='${SCRIPTDIR}/gen_sub_crys crys'" >> ${HOME}/.bashrc
    echo "alias Pprop='${SCRIPTDIR}/gen_sub_crys prop'" >> ${HOME}/.bashrc
    echo "alias setcrys='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/gen_sub_crys" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runcryP" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runpropP" >> ${HOME}/.bashrc 
    echo "chmod 777 ${SCRIPTDIR}/post_processing" >> ${HOME}/.bashrc 
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

    setcrys - print the file 'settings'
	
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
