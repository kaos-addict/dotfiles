#!/bin/bash
# Simple installer for few dot files
if [ -z "${1}" ];then
    echo -e "ERROR:\n${0} needs a distribution name as argument\nExample:\n${0} manjaro" && exit 1
else
    cat bash_aliases ${1}/${1}_aliases perso/perso_aliases > ~/.bash_aliases
    cat bash_functions ${1}/${1}_functions perso/perso_functions > ~/.bash_functions
    if [ -f "${1}/post-${1}-install.sh" ]
        then bash -c "${1}/post-${1}-install.sh"
    fi
fi
exit 0
