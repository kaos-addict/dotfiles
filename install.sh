#!/bin/bash
# Simple installer for few dot files
# Put basic files (bashrc) then add distrib specific one (kaos/kaos.bashrc) in ~/.bashrc
#                 (bash_aliases)                         (kaos/kaos.bash_aliases) in ~/.bash_aliases
# Need only distrib name as arg (must be the same as folder's name)

if [ -z "${1}" ];then
    echo -e "ERROR:\n${0} needs a distribution name as argument\nExample:\n${0} manjaro" && exit 1
elif [ ! -d "${1}" ];then
    echo -e "ERROR:\nArgument is not an existing folder... (There's no "${1}" in $(basedir ${0}))...\nExiting..."
else
    cat bashrc ${1}/${1}.bashrc > ~/.bashrc
    cat bash_aliases ${1}/${1}_aliases perso/perso_aliases > ~/.bash_aliases
    cat bash_functions ${1}/${1}_functions perso/perso_functions > ~/.bash_functions
    if [ -f "${1}/post-${1}-install.sh" ]
        then bash -c "${1}/post-${1}-install.sh"
    fi
fi
exit 0
