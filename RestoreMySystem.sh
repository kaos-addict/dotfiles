#!/bin/bash
# Simple installer for few dot files
# Put basic files (bashrc) then add distrib specific one (kaos/kaos.bashrc) in ${TargetDir}.bashrc
#                 (bash_aliases)                         (kaos/kaos.bash_aliases) in ${TargetDir}.bash_aliases
# Then add Desktops ones
# For now this script is specific to me on my KaOS Linux system and is targeted to quick restore my desktop environment
# But it should be adaptable and usable for more/any linux distro next.

Usage=$(cat << EOF
$0 [Step] [--only]
Each Step include the Steps before, where Steps are:
        postinstall: 
                                Update system, update few system adjustements and install some needed and optionaly extras packages.
        bashinstall: 
                                Install personnalized bashrc, bash_aliases, bash-functions and optionaly some prompt adds and boosts.
        userinstall: 
                                Restore your personnal backup and preferences.
        etcinstall: 
                                Restore system's backup and preferences.

        --postinstall | -p : Run all restoration steps even they have already been ran.
        
        --bashinstall | -b : Run all restoration steps from bashinstall even if they have been already ran.
        
        --userinstall | -u : Run all restoration steps from userinstall even if they have been already ran.
        
        --etcinstall | -e : Run all restoration steps from etcinstall even if they have been already ran.
        
Then if you add the --only or -o as second arg, it will run only the named Step
e.g: 
$ $0 --bashinstall --only # or
$ $0 -b -o
will run only the bashinstall step, even if it has been already ran.
EOF
)

TargetDir="${HOME}"
RunDir="$(dirname $0)"
yad=$(which yad)
DesktopList="Plasma Enlightenment Gnome Mate Xfce Lxde Lxqt Openbox Kde4"
WinIcon="${RunDir}/pix/Restore.svg"

# First verify we can dialog thru X
if [ -z "$(which yad)" ] && [ -z $(which kdialog) ] && [ -z $(which zenity) ];then
        echo "Sorry, this script need kdialog or yad or zenity to run."
        exit 1
fi

Dial=$($(which yad) || $(which zenity) || $(which kdialog))

# Create some memory file
Confile="$HOME/.config/${Distrib}-restore.log"
if [ ! -f "${Confile}" ];then
        echo "">>${Confile}
fi

# Error message
_error() {
        if [ "${Dial}" = "yad" ];then
                yad --title="$(basename $0 .sh)" --text="$1" --image=gtk-error --nobuttons --button:Ok:0 --window-icon="${WinIcon}"
        elif [ "${Dial}" = "zenity" ] || [ "${Dial}" = "qarma" ];then
                zenity --text="$1" --no-label="Ok" --window-icon="${WinIcon}"
        elif [ "${Dial}" = "kdialog" ];then
                kdialog --error "$1"
        else
                echo -e "$1"
        fi         
}

# Error message and exit
_errorexit() {
        if [ "${Dial}" = "yad" ];then
                yad --title="$(basename $0 .sh)" --text="$1" --image=gtk-error --nobuttons --button:Ok:0 --window-icon="${WinIcon}" && exit 0;
        elif [ "${Dial}" = "zenity" ] || [ "${Dial}" = "qarma" ];then
                zenity --text="$1" --no-label="Ok" --window-icon="${WinIcon}" && exit 0;
        elif [ "${Dial}" = "kdialog" ];then
                kdialog --error "$1" && exit 0;
        else
                echo -e "$1" && exit 0;
        fi         
}

# Make copy with .ori backup
cpb() { cp $@{,.ori} ;}

# For now this just verify we are on a KaOS system but it shoud next identify which distrib it is
if [ -f /etc/lsb-release ]
then
        Distrib=$(grep "DISTRIB_ID=" /etc/lsb-release | cut -d '=' -f 2)
        case ${Distrib} in
        "KaOS") if [  -d ${RunDir}/Distrib/KaOS ] && [ -d ${RunDir}/Desktops/Plasma ] ;then
                                _echo='kdialog --title "KaOS Dotfiles Restore" --msgbox'
                                _Desktop=Plasma
                        else
                                _errorexit "Sorry but Distribution can't be identified or some folders are missing..."
                        fi
        "Manjaro")if [  -d ${RunDir}/Distrib/Manjaro ];then
                                        _echo="${yad} --title='${Distrib} Dotfiles Restore' --text"
                                        _Desktop=$(AskDesktop)
                                 else
                                        _errorexit "Sorry Distribution $Distrib is not yet supported, give a help..."
                                fi
        "Debian")if [  -d ${RunDir}/Distrib/Debian ];then
                                        _echo="${yad} --title='${Distrib} Dotfiles Restore' --text"
                                        _Desktop=$(AskDesktop)
                                else
                                        _errorexit "Sorry Distribution $Distrib is not yet supported, give a help..."
                                fi
        "Ubuntu")if [  -d ${RunDir}/Distrib/Ubuntu ];then
                                        _echo="$(which zenity) --title='${Distrib} Dotfiles Restore' --text"
                                        _Desktop=$(AskDesktop)
                                else
                                        _errorexit "Sorry Distribution $Distrib is not yet supported, give a help..."
                                fi
        *) echo "/etc/lsb-release file not found, or distribution cannot be identified... Exiting..."
        exit 1
fi

# Once identified it should run the appropriate distrib specific install-script
_postinstall() {
case "$1" in 
        "KaOS")DistribDir="${RunDir}/Distrib/$1"
                [ -f ${DistribDir}/$1-post-install.sh ] && chmod +x ${DistribDir}/$1-post-install.sh && $1_postinstall || exit 1;;
        "Manjaro") echo "Doing Manja stuff... Soon...";;
        "Debian") echo "First install pacapt... Soon...";;
        "Ubuntu") echo "First install pacapt... Soon...";;
        *) echo "Distribution not (yet?) supported" && return 1;;
esac
}

KaOS_postinstall() {
# Not sure how it should be launch...
[ "$?" = "0" ] && bash -x ${DistribDir}/KaOS-post-install.sh || return 1
}

#Ask for used desktop
AskDesktop() {
        for d in ${DesktopList};do echo FALSE ${d};done | ${yad} --text="Which Desktop do you use?\n" \
        --list --radiolist --column="Installed" --column="Desktop" \
        --listen --print-column=2
}

## Bash files
_bashinstall() {
# For now only restore few dotfiles but then should ask for lib to use etc...
        # Save existing files
        if [ -f $HOME/.bashrc ];then cpb $HOME/.bashrc;fi
        if [ -f $HOME/.bash_aliases ];then cpb $HOME/.bash_aliases;fi
        if [ -f $HOME/.bash_functions ];then cpb $HOME/.bash_functions;fi
        
        cat bashrc Distrib/${1}/${1}.bashrc > ${TargetDir}/.bashrc || return 1	# Copy bashrc
        if [ -f ${RunDir}/Desktops/${_Desktop}/bash_aliases ];then
                cat bash_aliases ${1}/${1}_aliases perso/perso_aliases Desktops/${_Desktop}/bash_aliases > ${TargetDir}/.bash_aliases
        else
                cat bash_aliases ${1}/${1}_aliases perso/perso_aliases > ${TargetDir}/.bash_aliases
        fi
        if [ -f ${RunDir}/Desktops/${_Desktop}/bash_functions ];then
                cat bash_functions ${1}/${1}_functions perso/perso_functions Desktops/${_Desktop}/bash_functions > ${TargetDir}/.bash_functions
        else     
                cat bash_functions ${1}/${1}_functions perso/perso_functions > ${TargetDir}/.bash_functions || return 1    # Create .bash_functions
        fi
        
        # Want to boost bash?
        # Awesome fonts?
        if [ -d "${RunDir}/fonts" ];then 
                ${yad} --text='Do you want to install extras and awesome fonts?'
        fi
        if  [ "$?" = "0" ];then 
                ${_terminal} -e "./install.sh"
        fi
        
        # TODO: better getopt?
        # Liquidpromt?
        # powerline?
        
        if [ -f "${1}/post-${1}-install.sh" ]   # If exists, run post-install script
        then echo -e "Running post install script now..." && ./${1}/post-${1}-install.sh || return 1
    fi
    echo -e 'Dot files installed!\nBye!'
    return 0
}

## /etc files voir peut-être etckeeper?
_etcinstall() {
    # Need root privileges
    if [[ ${EUID} -ne 0 ]]; then
	echo -e "\e[31mThis script must be run by root\!\nExiting now...\e[0m"
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

_userinstall() {
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

# .config dir TODO:and personnal stuff
rsync --remove-source-files .config/ ${HOME}/.config/ && find -type d -empty -delete
return 0
}

# Check if step has been done
_istatus() {
        [ -n "$(grep $1 ${Confile})" ] && echo off || echo on
}

# Control what step to do
Steps=( '_postinstall' '_bashinstall' '_configinstall' '_etcinstall' )
Steps2do=( $(kdialog --title "What should we do?" --checklist "Choose the step(s) which should be run: " _postinstall 'Post Installation and update.' $(echo $(_istatus post)) _bashinstall 'Bash files installation' $(echo $(_istatus bash)) _configinstall 'Config files and personnal files restoration.' $(echo $(_istatus perso)) _etcinstall 'System files restoration' $(echo $(_istatus sys)) 2>/dev/null) )

case "$1" in
        "--postinstall" | "-p") if [ -z "$2" ];then
        for Act in "_bashinstall  _userinstall _etcinstall" 
                do ${Act} ${Distrib} || _error "Errors happened while ${Act}"
        done
        elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
                _postinstall ${Distrib} || _error "Errors happened while running post-install process."
        fi
        ;;
        "--bashinstall" | "-b") if [ -z "$2" ];then
        for Act in "_bashinstall  _userinstall _etcinstall" 
                do $(${Act}) ${Distrib} || _error "Errors happened while ${Act}"
        done 
        elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
                _bashinstall ${Distrib} || _error "Errors happened while running post-install process."
        fi
        ;;
        "--userinstall" | "-u") if [ -z "$2" ];then
        for Act in " _userinstall _etcinstall" 
                do $(${Act}) ${Distrib} || _error "Errors happened while ${Act}"
        done 
        elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
                _bashinstall ${Distrib} || _error "Errors happened while running post-install process."
        fi
        ;;
        "--etcinstall" | "-e")
        _etcinstall ${Distrib} || _error "Errors happened"
        ;;
        *) 
        for a in ${Steps2do[@]}
                do $(eval ${a} ${Distrib}) || _error "Error while ${a}"
        done
        ;;
esac
