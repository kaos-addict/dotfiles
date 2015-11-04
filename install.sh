#!/bin/bash
# Simple installer for few dot files
# Put basic files (bashrc) then add distrib specific one (kaos/kaos.bashrc) in ${TargetDir}.bashrc
#                 (bash_aliases)                         (kaos/kaos.bash_aliases) in ${TargetDir}.bash_aliases
# Need only distrib name as arg (must be the same as folder's name)

TargetDir="${HOME}"

## Bash files
_bashinstall() {
    cat bashrc ${1}/${1}.bashrc > ${TargetDir}/.bashrc || return 1	# Copy bashrc
    cat bash_aliases ${1}/${1}_aliases perso/perso_aliases > ${TargetDir}/.bash_aliases || return 1    # Create .bash_aliases
    cat bash_functions ${1}/${1}_functions perso/perso_functions > ${TargetDir}/.bash_functions || return 1    # Create .bash_functions
    if [ -f "${1}/post-${1}-install.sh" ]   # If exists, run post-install script
        then ./${1}/post-${1}-install.sh || return 1
    fi
    return 0
}


### Verify
if [ -z "${1}" ];then   # If there's argument
    echo -e "ERROR:\n${0} needs a distribution name as argument\nExample:\n${0} manjaro" && exit 1
elif [ ! -d "${1}" ];then   # If argument exist as a folder
    echo -e "ERROR:\nArgument is not an existing folder... (There's no "${1}" in $(basedir ${0}))...\nExiting..."
else
    _bashinstall "${1}"
    if [ "${?}" = "1" ];then echo -e 'Shit happened!!! Sorry...';fi
fi

echo -e 'Dot files installed!\nBye!'
exit 0
