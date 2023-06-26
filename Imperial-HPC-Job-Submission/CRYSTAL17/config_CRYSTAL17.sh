#!/bin/bash

function welcome_msg {
    core_version=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_date=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_author=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_contact=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_acknolg=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_version=`grep 'CRYSTAL17' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_date=`grep 'CRYSTAL17' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_author=`grep 'CRYSTAL17' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_contact=`grep 'CRYSTAL17' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_acknolg=`grep 'CRYSTAL17' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
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
CRYSTAL17 job submission script for Imperial HPC - Setting up

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
    ${HOME}/etc/runCRYSTAL17/):

EOF

    read -p " " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/etc/runCRYSTAL17
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
    Please specify the directory of CRYSTAL17 exectuables, 
    or the command to load CRYSTAL17 modules

    Default Option
    cry17gnu v2.2 (mpich - ifort - MPP)

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='/rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/bin/Linux-mpigfortran_MPP/Xeon___mpich__3.2.1'
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
    mpich/3.2.1

EOF
    
    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
        MPIDIR='module load /rds/general/user/gmallia/home/CRYSTAL17_cx1/v2.2gnu/modules/mpich/3.2.1'
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
    sed -i "/JOB_TMPDIR/a\ ${EPHEMERAL}" ${SETFILE}
    sed -i "/EXEDIR/a\ ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}

    # Executable table

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
    sed -i "${LINE_EXE}a\sprop                                                                   properties < INPUT                                           Serial properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\scrys                                                                   crystal < INPUT                                              Serial crystal calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pprop      mpiexec                                                      Pproperties                                                  Parallel properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\mppcrys    mpiexec                                                      MPPcrystal                                                   Massive parallel crystal calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pcrys      mpiexec                                                      Pcrystal                                                     Parallel crystal calculation" ${SETFILE}

    # Input file table

    LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
    sed -i "${LINE_PRE}a\[jobname].POINTCHG   POINTCHG.INP         Dummy atoms with 0 mass and given charge" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].gui        fort.34              Geometry input" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].d3         INPUT                Properties input file" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].d12        INPUT                Crystal input file" ${SETFILE}
    
    # Reference file table

	LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`
    sed -i "${LINE_REF}a\[refname].f31        fort.32              Derivative of density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f80        fort.81              Wannier funcion - input" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f28        fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f13        fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].TENS_RAMAN TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].BORN       BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].FREQINFO   FREQINFO.DAT         Frequency restart data" ${SETFILE}
	sed -i "${LINE_REF}a\[refname].freqtsk/   *                    Frequency multitask restart data" ${SETFILE}
	sed -i "${LINE_REF}a\[refname].EOSINFO    EOSINFO.DAT          Equation of state restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].OPTINFO    OPTINFO.DAT          Optimisation restart data" ${SETFILE}
	sed -i "${LINE_REF}a\[refname].f9         fort.9               Last step wavefunction - properties input" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f9         fort.20              Last step wavefunction - crystal input" ${SETFILE}
    
    # Post-processing file table

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`
    
    sed -i "${LINE_POST}a\[jobname].POTC       POTC.DAT             Electrostatic potential and derivatives" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname]_POT.CUBE   POT_CUBE.DAT         3D electrostatic potential CUBE format  " ${SETFILE}
    sed -i "${LINE_POST}a\[jobname]_SPIN.CUBE  SPIN_CUBE.DAT        3D spin density CUBE format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].RHOLINE    RHOLINE.DAT          1D charge density and gradient" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname]_CHG.CUBE   DENS_CUBE.DAT        3D charge density Gaussian CUBE format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].DOSS       DOSS.DAT             DOS xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].BAND       BAND.DAT             Band xmgrace format " ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].DIEL       DIEL.DAT             Dielectric constants" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].KRED       KRED.DAT             K space information for cryapi_inp" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].GRED       GRED.DAT             Real space information for cryapi_inp" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f31        fort.31              Derivative of density matrix / Proeprties 3D grid data" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].EOSINFO    EOSINFO.DAT          QHA and equation of states information" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].TENS_RAMAN TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].RAMSPEC    RAMSPEC.DAT          Raman spectra" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].BORN       BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].IRSPEC     IRSPEC.DAT           IR absorbance and reflectance" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].IRREFR     IRREFR.DAT           IR refractive index" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].IRDIEL     IRDIEL.DAT           IR dielectric function" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].PHONBANDS  PHONBANDS.DAT        Phonon bands xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f25        fort.25              Data in Crgra2006 format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].scanmode/  SCAN*                Displaced geometry along scanned mode" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f80        fort.80              Wannier funcion - output" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f28        fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f13        fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].FREQINFO   FREQINFO.DAT         Frequency restart data" ${SETFILE}
	sed -i "${LINE_POST}a\[jobname].freqtsk/   FREQINFO.DAT.tsk*    Frequency multitask restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].optstory/  opt*                 Optimised geometry per step " ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].HESSOPT    HESSOPT.DAT          Hessian matrix per optimisation step" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].OPTINFO    OPTINFO.DAT          Optimisation restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].SCFLOG     SCFOUT.LOG           SCF output per step" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].PPAN       PPAN.DAT             Mulliken population" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f98        fort.98              Formatted wavefunction" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f9         fort.9               Last step wavefunction - crystal output" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].STRUC      STRUC.INCOOR         Geometry, STRUC.INCOOR format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].GAUSSIAN   GAUSSIAN.DAT         Geometry, for Gaussian98/03" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].FINDSYM    FINDSYM.DAT          Geometry, for FINDSYM" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].cif        GEOMETRY.CIF         Geometry, cif format (CIFPRT/CIFPRTSYM)" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].xyz        fort.33              Geometry, non-periodic xyz format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].gui        fort.34              Geometry, CRYSTAL fort34 format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].ERROR      fort.87              Error report" ${SETFILE}

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

# Configure user alias

function set_commands {
    bgline=`grep -nw "# >>> begin CRYSTAL17 job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish CRYSTAL17 job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin CRYSTAL17 job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcrys17='${CTRLDIR}/gen_sub -x pcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias MPPcrys17='${CTRLDIR}/gen_sub -x mppcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Pprop17='${CTRLDIR}/gen_sub -x pprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Scrys17='${CTRLDIR}/gen_sub -x scrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Sprop17='${CTRLDIR}/gen_sub -x sprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xcrys17='${CTRLDIR}/gen_sub -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETcrys17='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPcrys17='bash ${CONFIGDIR}/run_help gensub'" >> ${HOME}/.bashrc
    # echo "chmod 777 $(dirname $0)/gen_sub" >> ${HOME}/.bashrc
    # echo "chmod 777 $(dirname $0)/run_exec" >> ${HOME}/.bashrc
    # echo "chmod 777 $(dirname $0)/post_proc" >> ${HOME}/.bashrc 
    # echo "chmod 777 $(dirname $0)/run_help" >> ${HOME}/.bashrc 
    echo "# <<< finish CRYSTAL17 job submitter settings <<<" >> ${HOME}/.bashrc
    
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
