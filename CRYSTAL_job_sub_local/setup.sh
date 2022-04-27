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
CRYSTAL17 job submitter for local servers - Setting up

Job submitter installed at: `date`
Job submitter edition:      v0.1

By Spica-Vir, Apr.27, 22, ICL, spica.h.zhou@gmail.com

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
    Please specify the directory of CRYSTAL exectuables:

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
    Error: Directory does not exist. Exiting current job. 

EOF
        exit
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
    sed -i "/EXE_CRYSTAL/a crystal" ${SETFILE}
    sed -i "/EXE_PROPERTIES/a properties" ${SETFILE}

    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}. 
    Note that job submission tempelate should be placed at the end of the file. 

EOF
}

function set_commands {
    sed -i '/CRYSTAL job submitter settings/d' ${HOME}/.bashrc
    sed -i '/setcrys=/d' ${HOME}/.bashrc
    sed -i '/runcrys/d' ${HOME}/.bashrc
    sed -i '/runprop/d' ${HOME}/.bashrc

    echo "# >>> CRYSTAL job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias crystal='${SCRIPTDIR}/runcrys'" >> ${HOME}/.bashrc
    echo "alias property='${SCRIPTDIR}/runprop'" >> ${HOME}/.bashrc
    echo "alias setcrys='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runcrys" >> ${HOME}/.bashrc
    echo "chmod 777 ${SCRIPTDIR}/runprop" >> ${HOME}/.bashrc 
    echo "# <<< finish CRYSTAL job submitter settings <<<" >> ${HOME}/.bashrc

    source ${HOME}/.bashrc

    cat << EOF
================================================================================
    User defined commands set, including: 

    crystal - executing crystal calculations

        crystal jobname [refname]

        jobname:  str, name of input .d12 file
        refname:  str, optional, name of the previous job

    property - executing properties calculations

        property jobname SCFname

        jobname:  str, name of input .d3 file
        SCFname:  str, name of the previous 'crystal' job

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
