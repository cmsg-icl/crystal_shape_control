#!/bin/bash

#---- BEGIN_USER ----# A reminder of providing version & other information to version_control.txt file. All 'CRYSTAL17' should be substituted
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
CRYSTAL17 job submission script for NHPC101 - Setting up

Job submission script installed date : `date`
Job submission script version        : ${code_version} (${code_date})
Job submission script author         : ${code_author} (${code_contact})
Core script version                  : ${core_version} (${core_date})
Job submission script author         : ${core_author} (${core_contact})

${code_acknolg}
${core_acknolg}

EOF
}
#---- END_USER ----#

function get_scriptdir {
#---- BEGIN_USER ----# version number
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path.

    Default Option
    ~/etc/runCRYSTAL17

EOF
#---- END_USER ----#

    read -p " " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then
#---- BEGIN_USER ----# if input is empty, use default
        SCRIPTDIR="${HOME}/etc/runCRYSTAL17"
#---- END_USER ----#
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

function set_exe {
#---- BEGIN_USER ----# version number
    cat << EOF
================================================================================
    Please specify the directory of CRYSTAL exectuables, 
    or the command to load CRYSTAL modules

    Default Option
    CRYSTAL/17v1.0.1-intel

EOF
#---- END_USER ----#
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
#---- BEGIN_USER ----# if input is empty, use default
        EXEDIR='module load CRYSTAL/17v1.0.1-intel'
#---- END_USER ----#
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
#---- BEGIN_USER ----# version number
    cat << EOF
================================================================================
    Please specify the directory of MPI executables or mpi modules

    Default Option
    RunEnv/Intel-2023.1.0

EOF
#---- END_USER ----#
    
    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
#---- BEGIN_USER ----# if input is empty, use default
        MPIDIR='module load RunEnv/Intel-2023.1.0'
#---- END_USER ----#
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
    # sed -i "/SUBMISSION_EXT/a\.slurm" ${SETFILE}
#---- BEGIN_USER ----#
    # sed -i "/NCPU_PER_NODE/a\128" ${SETFILE}
    # sed -i "/NTHREAD_PER_PROC/a\ 1" ${SETFILE}
    # sed -i "/BUDGET_CODE/a\ ${BUDGET_CODE}" ${SETFILE}
    # sed -i "/QOS/a\standard" ${SETFILE}
    # sed -i "/PARTITION/a\standard" ${SETFILE}
    # sed -i "/TIME_OUT/a\3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\ default" ${SETFILE}
#---- END_USER ----#
    sed -i "/EXEDIR/a\ ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}

    # Executable table

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
#---- BEGIN_USER ----# MPI+executable options
    sed -i "${LINE_EXE}a\pprop      mpiexec -np 1                                                properties < INPUT                                           Serial properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\scrys      mpiexec -np 1                                                crystal < INPUT                                              Serial crystal calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pprop      mpiexec -np \${V_NP}                                          Pproperties                                                  Parallel properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\mppcrys    mpiexec -np \${V_NP}                                          MPPcrystal                                                   Massive parallel crystal calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pcrys      mpiexec -np \${V_NP}                                          Pcrystal                                                     Parallel crystal calculation" ${SETFILE}
#---- END_USER ----#
    # Input file table

    LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
#---- BEGIN_USER ----# Files with [jobname] or [job]
    sed -i "${LINE_PRE}a\[jobname].POINTCHG   POINTCHG.INP         Dummy atoms with 0 mass and given charge" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].gui        fort.34              Geometry input" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].d3         INPUT                Properties input file" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].d12        INPUT                Crystal input file" ${SETFILE}
#---- END_USER ----#
    # Reference file table

    LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`
#---- BEGIN_USER ----# Files with [refname] or [ref]
    sed -i "${LINE_REF}a\[refname].f31        fort.32              Derivative of density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f80        fort.81              Wannier funcion - input" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f28        fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f13        fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].TENS_RAMAN TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].BORN       BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].freqtsk/   *                    Frequency restart data multitask" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].FREQINFO   FREQINFO.DAT         Frequency restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].OPTINFO    OPTINFO.DAT          Optimisation restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f9         fort.9               Last step wavefunction - properties input" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].f9         fort.20              Last step wavefunction - crystal input" ${SETFILE}
#---- END_USER ----# 
    # Post-processing file table

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`
#---- BEGIN_USER ----# Output files
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
    sed -i "${LINE_POST}a\[jobname].PHONDOS    PHONDOS.DAT          Phonon DOS xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].PHONBANDS  PHONBANDS.DAT        Phonon bands xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f25        fort.25              Data in Crgra2006 format" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].scanmode/  SCAN*                Displaced geometry along scanned mode" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f80        fort.80              Wannier funcion - output" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f28        fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].f13        fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].freqtsk/   FREQINFO.DAT.tsk*    Frequency restart data multitask" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].FREQINFO   FREQINFO.DAT         Frequency restart data" ${SETFILE}
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
#---- END_USER ----#
    # Job submission file template - Not used.
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}.

EOF
}

# Configure user alias

function set_commands {
#---- BEGIN_USER ----# Cover the old alias commands block
    bgline=`grep -nw "# >>> begin CRYSTAL17 job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish CRYSTAL17 job submitter settings <<<" ${HOME}/.bashrc`
#---- END_USER ----#

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi
#---- BEGIN_USER ----# Alias commands. The 'chmod' command should be kept unmodified
    echo "# >>> begin CRYSTAL17 job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcrys17='${CTRLDIR}/run_job -x pcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias MPPcrys17='${CTRLDIR}/run_job -x mppcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Pprop17='${CTRLDIR}/run_job -x pprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Scrys17='${CTRLDIR}/run_job -x scrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Sprop17='${CTRLDIR}/run_job -x sprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xcrys17='${CTRLDIR}/run_job -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETcrys17='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPcrys17='bash ${CONFIGDIR}/run_help gensub'" >> ${HOME}/.bashrc
    echo "chmod -R 'u+r+w+x' ${CTRLDIR}" >> ${HOME}/.bashrc
    echo "chmod 'u+r+w+x' ${CONFIGDIR}/run_help" >> ${HOME}/.bashrc
    echo "# <<< finish CRYSTAL17 job submitter settings <<<" >> ${HOME}/.bashrc
#---- END_USER ----# 
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
