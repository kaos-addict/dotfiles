#!/bin/bash
# Simple installer for few dot files
# TODO: Put basic files (bashrc) then add distrib specific one (kaos/kaos.bashrc) in ${TargetDir}.bashrc
#                 (bash_aliases)                         (kaos/kaos.bash_aliases) in ${TargetDir}.bash_aliases
# Then add Desktop ones
# Need only distrib name as arg (must be the same as folder's name)
# For now this script is specific to me on my KaOS Linux system and is targeted to quick restore my desktop environment
# But it should be adaptable and usable for more/any linux distro next.

TargetDir="${HOME}"
RunDir="$(dirname $0)"

# For now this just verify we are on a KaOS system but it shoud next identify which distrib it is
if [ -f /etc/lsb-release ]
then
        Distrib=$(grep "DISTRIB_ID=" /etc/lsb-release | cut -d '=' -f 2)
        [ "${Distrib}" = "KaOS" ] && [  -d ${RunDir}/Distrib/KaOS ] && [ -d ${RunDir}/Desktops/Plasma ] && \
        _echo='kdialog --title "KaOS Dotfiles Restore" --msgbox' || exit 1
else 
        exit 1
fi

PostInstall() {
# Once identified it should run the appropriate distrib specific install-script
case "$1" in 
        "KaOS")DistribDir="${RunDir}/Distrib/KaOS"; [ -f ${DistribDir}/KaOS-post-install.sh ] && chmod +x ${DistribDir}/KaOS-post-install.sh && K_PostInstall || exit 1;;
        "Manjaro") Echo "Doing Manja stuff";;
        *) echo "Distribution not (yet?) supported" && return 1;;
esac
}

K_PostInstall() {
# Not sure how it should be launch...
kdialog --title "KaOS Dotfiles Restore" --text "Launching KaOS Linux Install script?" --textbox ${DistribDir}/KaOS-post-install.sh
# Run install script?
[ "$?" = "0" ] && bash -c ${DistribDir}/KaOS-post-install.sh || return 1
}

## Bash files
_bashinstall() {
# For now only restore few dotfiles but then should ask for lib to use etc...
    cat bashrc ${1}/${1}.bashrc > ${TargetDir}/.bashrc || return 1	# Copy bashrc
    cat bash_aliases ${1}/${1}_aliases perso/perso_aliases > ${TargetDir}/.bash_aliases || return 1    # Create .bash_aliases
    cat bash_functions ${1}/${1}_functions perso/perso_functions > ${TargetDir}/.bash_functions || return 1    # Create .bash_functions
    if [ -f "${1}/post-${1}-install.sh" ]   # If exists, run post-install script
        then ./${1}/post-${1}-install.sh || return 1
    fi
    echo -e 'Dot files installed!\nBye!'
    return 0
}

## /etc files voir peut-être etckeeper?
_etcinstall() {
    # Need root privileges
    if [[ ${EUID} -ne 0 ]]; then
	echo -e "\e[31mThis script must be run by root!\nExiting now...\e[0m"
﻿	exit 1
    fi
    rsync -r -x -c -b -i -s etc/ /etc/ || return 1
}

### Git-config
_gitconf() {
    Name=""
    Email=""
    read -r -p "Enter your name" Name
    if  [ -n ${Name} ];then sed -e "s/NAME/${Name}/g" perso/gitconfig ${TargetDir}/.gitconfig;fi
    read -r -p "Enter your email address" Email
    if  [ -n ${Email} ];then sed -i "s/EMAIL/${Email}/g" ${TargetDir}/.gitconfig;fi
}

PersoInstall() {

# VARIABLES
Savef=mermouy.dot
Sext=tar.bz2
Source=/media/Remise/save
Wkdir=/tmp

# Extract savefiles
cd ${Wkdir}
case ${Sext} in
    tar.bz2) tar -xvjf ${Source}/${Savef}.${Sext} || echo "Problem while extracting tar.bz2 savefiles";;
    tar.gz) tar -xvzf ${Source}/${Savef}.${Sext} || echo "Problem while extracting tar.gz savefiles";;
    tar.xz) tar -xvJf ${Source}/${Savef}.${Sext} || echo "Problem while extracting tar.xz savefiles";;
esac

### TODO: Other dot files

### TODO: confirmation dialog (qarma?)

# .config dir TODO:and personnal stuff
rsync --remove-source-files .config/ ${HOME}/.config/ && find -type d -empty -delete
return 0
}

# Control what step to do
case "$1" in
        "") PostInstall ${Distrib};;
        "Postinstall") _bashinstall;;
        "LastInstall") echo "Last install part";;
esac
