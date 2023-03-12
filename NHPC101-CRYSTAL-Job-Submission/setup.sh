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
CRYSTAL17 job submitter for local servers (No job schedular) - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.3

By Spica-Vir, May 6, 22, ICL, spica.h.zhou@gmail.com

Developed based on Dr G.Mallia's scripts on Imperial cluster
Special thanks to G.Mallia & N.M.Harrison

EOF
}

function get_scriptdir {
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path (by default ${HOME}/etc/runCRYSTAL/):

EOF

    read -p " " SCRIPTDIR
    SCRIPTDIR=`echo ${SCRIPTDIR}`

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${HOME}/etc/runCRYSTAL/
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
    Please specify the directory or module name of CRYSTAL exectuables:

EOF
    
    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
                cat << EOF
--------------------------------------------------------------------------------
    Error: Directory must be specified. Exiting current job. 

EOF
    fi

    if [[ ! -s ${EXEDIR} || ! -e ${EXEDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Warning: Directory does not exist. Input will be recognised as a module name.

EOF
    fi
}

function copy_scripts {
    curr_dir=`pwd`

    if [[ ${SCRIPTDIR} != ${curr_dir} ]]; then
        mkdir -p             ${SCRIPTDIR}
        cp runcrys           ${SCRIPTDIR}/runcrys
        cp runprop           ${SCRIPTDIR}/runprop
        cp settings_template ${SCRIPTDIR}/settings
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
    sed -i "/CRYSTAL_SCRIPT/a runcrys" ${SETFILE}
    sed -i "/PROPERTIES_SCRIPT/a runprop" ${SETFILE}
    sed -i "/EXEDIR/a ${EXEDIR}" ${SETFILE}
    sed -i "/EXE_PCRYSTAL/a Pcrystal" ${SETFILE}
    sed -i "/EXE_MPP/a MPPcrystal" ${SETFILE}
    sed -i "/EXE_PPROPERTIES/a Pproperties" ${SETFILE}
    sed -i "/EXE_CRYSTAL/a crystal" ${SETFILE}
    sed -i "/EXE_PROPERTIES/a properties" ${SETFILE}

    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 

EOF
}

function set_commands {
    bgline=`grep -nw "# >>> CRYSTAL job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish CRYSTAL job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> CRYSTAL job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias crys=\"${SCRIPTDIR}/runcrys --np 1\"" >> ${HOME}/.bashrc
    echo "alias prop=\"${SCRIPTDIR}/runprop --np 1\"" >> ${HOME}/.bashrc
    echo "alias Pcrys=\"${SCRIPTDIR}/runcrys\"" >> ${HOME}/.bashrc
    echo "alias Pprop=\"${SCRIPTDIR}/runprop\"" >> ${HOME}/.bashrc
    echo "alias setcrys=\"cat ${SCRIPTDIR}/settings\"" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runcrys" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runprop" >> ${HOME}/.bashrc 
    echo "# <<< finish CRYSTAL job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    crystal - executing serial crystal calculations

        crys --in jobname [--ref refname]

        jobname:  str, name of input .d12 file, basename recommanded
        refname:  str, optional, name of the previous job, basename recommanded

    Pcrys - executing parallel crystal calculations

        Pcrys --in jobname [--ref refname] --np NCPU

        NCPU:  int, number of CPUs
        jobname:  str, name of input .d12 file, basename recommanded
        refname:  str, optional, name of the previous job, basename recommanded

    prop - executing serial properties calculations

        prop --in jobname --ref SCFname

        jobname:  str, name of input .d3 file, basename recommanded
        SCFname:  str, name of the previous 'crystal' job, basename recommanded

    Pprop - executing parallel properties calculations

        Pprop --in jobname --ref refname --np NCPU

        NCPU:  int, number of CPUs
        jobname:  str, name of input .d12 file, basename recommanded
        refname:  str, name of the previous job, basename recommanded

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
