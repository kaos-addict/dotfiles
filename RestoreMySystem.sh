#!/bin/bash

###############################################################################################################################

## PLEASE:
# You have to know that I can be lot of things but certainly not a developer! 
# I enjoy learning and playing with script, so please be teatcher and dad, more than laughing at... Also sorry for language...
# For script writing sheme I actually try to follow best last recommendations, 
# I hope I will have time to edit them at <https://github.com/kaos-addict/Habits/bash>
# Use same address'issues tab for ideas, advices, detected absurdities or any think on these.
# To make it clear: !!! THIS IS NOT AN USABLE SCRIPT !!! USE IT AT YOUR OWN RISKS.
# Objectives would be (in smoothests dreams) to code a tool to get back most of system as well as users apps and config files,
# it use 'kdialog', 'yad' and possibly soon some other X-dialog apps. 
# TO_THINK_ABOUT: should use Easybash to simplify X-dialog apps managment?
# For now, actually it's still a personnal script, but who knows?...
# Actually most (future detected) variables are hard coded, 
# so to look and why not trying this script: DO NOT FORGET TO EDIT VARIABLES (at least)
# For now, it just installs some (fresh installed system) missing softwares, fetch some of my preferences, and dotfiles
# But could later being used for multi-user config and apps, prompt personnalization etc...
###############################################################################################################################

# For now just few things work and should be re-usable, only for KaOS 
# Put basic files (bashrc) then add distrib specific one (kaos/kaos.bashrc) in ${TargetDir}.bashrc
#                 (bash_aliases)                         (kaos/kaos.bash_aliases) in ${TargetDir}.bash_aliases
# Then add Desktops ones
# Work In Progress: For now this script is specific to me on my KaOS Linux system
# and is targeted to quick restore my desktop environment,
# But it should be adaptable and usable for more/any linux distro in the future.

## TODO
# Must TODO's: (definitively needed) 
#   [ ] Add color once sourced
#   [ ] Find a way to detect hard coded values like :
#       [ ] Distrib name: should be detected instead of hardcoded Distrib variable
#       [ ] Kdialog references: best would be to use a wrapper until we detect which app are available or not. (Or easybashgui?)
#       [x] Username: Asked via X-dialog
#   [ ] General designs and images boost, text gramma etc... 
##

################
### Variables: #
################

# Set target & work folders

RunDir="$( cd "$(dirname "$0")" ; pwd -P )" # Best way to find script folder
DesktopList="Plasma Enlightenment Gnome Mate Xfce Lxde Lxqt Openbox Kde4"
WinIcon="${RunDir}/pix/Restore.svg"
Steps=( '_postinstall' '_bashinstall' '_configinstall' '_etcinstall' )
RestoreImg="${RunDir}/pix/Restore-Logo"
Confile="${TargetDir}/.config/${ProgName}.log"
Debug="-x" # Change to Debug="" if you don't need this

######################
### Utils-functions: #

# Test display with one of xdialogs or simply echo usage
UsageDisplay() {
        if [ "${Dial}" = "/usr/bin/yad" ];then
                Usage | /usr/bin/yad --title="'$(basename $0 .sh)' Help Display" \
                --window-icon=${WinIcon} --center --text-align=fill \
                --text="<b>Here you can see usage of </b>'$(basename $0 .sh)'<b> script:</b>\n" \
                --text-info --width 1050 --height 600 --button=gtk-close:0 \
                --image="${RestoreImg}-yad.png" --dialog-sep
        elif [ "${Dial}" = "/usr/bin/zenity" ] || [ "${Dial}" = "/usr/bin/qarma" ];then
                Usage > .$0.tmp
                ${Dial} --title="$(basename $0 .sh)" --window-icon=${WinIcon} \
                --text="$0 Help Display" --text-info --filename=".$0.tmp"
        elif [ "${Dial}" = "/usr/bin/kdialog" ];then
                ${Dial} --title "$(basename $0 .sh)" --window-icon=${WinIcon} \
                --detailederror "$0 Help Display" "$(Usage)"
        else
                Usage && exit 1
        fi
}

Usage() {
        cat << EOF
Must be run with sudo privilege! as

sudo $0 [Step] [--only]
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
        
        --etcinstall | -e : Run all restoration steps from etcinstall even if they have been already ran. (Cannot be used with the -o option)
        
Then if you add the --only or -o as second arg, it will run only the named Step
e.g: 
$ $0 --bashinstall --only # or
$ $0 -b -o
will run only the bashinstall step, even if it has been already ran.
EOF
}

# Error message
_error() {
        if [ "${Dial}" = "/usr/bin/yad" ]
        then 
            yad --title="$(basename $0 .sh)" --text="$1" --image=gtk-error --nobuttons --button:Ok:0 --window-icon="${WinIcon}"
        elif [ "${Dial}" = "/usr/bin/zenity" ] || [ "${Dial}" = "qarma" ]
        then
            zenity --text="$1" --no-label="Ok" --window-icon="${WinIcon}"
        elif [ "${Dial}" = "/usr/bin/kdialog" ]
        then 
            kdialog --icon ${WinIcon} --title ${ProgName} --error "$1"
        else echo -e ${Red}"$1"${C_Off}
        fi
}

# Error message and exit
_errorexit() {
    if [ "${Dial}" = "/usr/bin/yad" ]
    then 
        yad --title="$(basename $0 .sh)" --text="$1" --image=gtk-error --nobuttons --button:Ok:0 --window-icon="${WinIcon}" && exit 0;
    elif [ "${Dial}" = "/usr/bin/zenity" ] || [ "${Dial}" = "qarma" ]
    then 
        zenity --text="$1" --no-label="Ok" --window-icon="${WinIcon}" && exit 0;
    elif [ "${Dial}" = "/usr/bin/kdialog" ]
    then 
        kdialog --error "$1" && exit 0;
    else echo -e ${Red}"$1"${C_Off} && exit 0
    fi  
}

# Make copy with .ori backup
cpb() { cp $@{,.$(date -I).ori} ;}

### :Utils-functions #
######################

#######################
### Script functions: #

VeriF() {
    # Verify bash_colors are here and source them
    if [ ! -f ${RunDir}/bash_colors ];then 
            echo -e 'ERROR! Have you downloaded full archive?\nExiting...'
            exit 1 
    else . ./bash_colors
    fi

    # Verify an X-dialog is possible
    Dialist="kdialog yad zenity xdialog" # Usable interfaces
    # first found will be used:
    for app in ${Dialist}; do Dial="$(which ${app} 2>>/dev/null)" && break; done
    
    # If X-dialogs not found, exit with error message
    [ -z "${Dial}" ] && echo -e ${BRed}"Error...\n${Red}You need at least one of ${Green}'${Dialist}' ${Red}to run this script...\n${BYellow}Exiting...${C_Off}" && exit 1
    
    # Need root privileges
    if [[ ${EUID} -ne 0 ]];then
            kdesu $0 || _errorexit '<b>This script must be run by root!</b><br><br>You Should run with "sudo", "kdesu" or "xdgsu" prefix...<br><br>Exiting now...' || echo -e "\e[31mThis script must be run by root\!\nExiting now...\e[0m"
            exit 1
    fi
}

# Ask for username to install to:
AskUserName() {
    User=$(kdialog --title "$0" --inputbox "Please enter user name for which this should be installed: \nThis must neither be 'user' nor 'root'" "user")
    if [ $? != 0 ];then 
        _errorexit 'Cancelled by user.... Exiting now...'
    elif [ -z "${User}" ] || [ "${User}" = "user" ] || [ "${User}" = "root" ];then 
        _errorexit 'Username Not Given Or root user entered... Exiting...'
    elif [ ! -d "/home/${User}" ];then 
        _errorexit 'Given Username does not have a </home/username> folder... Exiting...'
    fi
    export TargetDir="/home/${User}"
}

# For now this just verify we are on a KaOS system but it shoud next identify which distrib it is
GetDistrib() {
    case "$(uname -m)" in
        "arm") _errorexit 'Sorry, Arm architecture is not yet supported...' ;;
        "x86") _errorexit 'Sorry, x86 architecture is not yet supported...' ;;
        "x86-64") if [ -f /etc/lsb-release ];then
                    declare $(grep "DISTRIB_ID" /etc/lsb-release)
                    
                    case "${DISTRIB_ID}" in
                        "KaOS") if [ -d ${RunDir}/Distrib/KaOS ] && [ -d ${RunDir}/Desktops/Plasma ];then
                                _echo='kdialog --title "KaOS Dotfiles Restore" --msgbox'
                                _Desktop=Plasma
                            else _errorexit "Sorry but Distribution can't be identified or some folders are missing...";fi 
                            ;;
                        "Manjaro") if [ -d ${RunDir}/Distrib/Manjaro ];then
                                    _echo="${yad} --title='${DISTRIB_ID} Dotfiles Restore' --text"
                                    _Desktop=$(AskDesktop) || _errorexit "Sorry Distribution $Distrib is not yet supported, give a help..."; fi
                            ;;
                        "Debian") if [  -d ${RunDir}/Distrib/Debian ];then
                                    _echo="${yad} --title='${DISTRIB_ID} Dotfiles Restore' --text"
                                    _Desktop=$(AskDesktop)
                                else _errorexit "Sorry Distribution $Distrib is not yet supported, give a help...";fi
                            ;;
                        "Ubuntu") if [  -d ${RunDir}/Distrib/Ubuntu ];then
                                _echo="$(which zenity) --title='${DISTRIB_ID} Dotfiles Restore' --text"
                                _Desktop=$(AskDesktop)
                            else _errorexit "Sorry Distribution $Distrib is not yet supported, give a help...";fi 
                            ;;
                        "*") echo ${Red}"Distribution cannot be identified...\n${BYellow}Exiting..."${C_Off} 
                            exit 1 
                            ;;
                    esac 
                else echo -e ${Green}"/etc/lsb-release ${Red}file not found\n... ${BYellow}Exiting..."${C_Off} && exit 2
                fi 
                ;;
        "*") _errorexit 'Unable to find Machine architecture' ;;
    esac
}

# Once identified it should run the appropriate distrib specific install-script
_postinstall() {
case $1 in 
        KaOS) DistribDir="${RunDir}/Distrib/KaOS"
                [ -f ${DistribDir}/KaOS-post-install.sh ] 
                chmod +x ${DistribDir}/KaOS-post-install.sh
                /bin/bash ${Debug} ${DistribDir}/KaOS-post-install.sh ${User} || _errorexit "Problem while launching ${DistribDir}/KaOS-post-install.sh
Exiting..."
        ;;
        Manjaro) echo ${BYellow}"Doing Manja stuff... Soon..."${C_Off} 
        ;;
        Debian) echo ${BYellow}"First install pacapt... Soon..."${C_Off} 
        ;;
        Ubuntu) echo ${BYellow}"First install pacapt... Soon..."${C_Off} 
        ;;
        *) echo -e ${Red}"Distribution not ${BRed}(yet?)${Red} supported...\n${BYellow}Exiting..."${C_Off} 
        ;;
esac
return 0
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
        
        if [ -f ${TargetDir}/.bashrc ];then cpb ${TargetDir}/.bashrc
                echo -e ${BGreen}"Bashrc Saved..."${C_Off}
        fi
        if [ -f ${TargetDir}/.bash_aliases ];then cpb ${TargetDir}/.bash_aliases
                echo -e ${BGreen}"Bash_aliases Saved..."${C_Off}
        fi
        if [ -f ${TargetDir}/.bash_functions ];then cpb ${TargetDir}/.bash_functions
                echo -e ${BGreen}"Bash_functions Saved..."${C_Off}
        fi
        
        cd ${RunDir}
        
        # Compile and copy bashrc TODO:Should detect what's available and what's not.
        
        if [ -f bashrc ] && [ -f Distrib/${1}/${1}_bashrc ] && [ -f perso/perso_bashrc ];then
            cat bashrc Distrib/${1}/${1}_bashrc perso/perso_bashrc > ${TargetDir}/.bashrc || return 1
        elif [ -f bashrc ] && [ -f Distrib/${1}/${1}_bashrc ];then
            cat bashrc Distrib/${1}/${1}_bashrc > ${TargetDir}/.bashrc || return 1
        elif [ -f bashrc ];then
            cat bashrc > ${TargetDir}/.bashrc || return 1
        else echo -e ${BRed}"No bashrc file found... Aborting..."${C_Off}
        fi

        echo -e ${BGreen}"Bashrc compiled and copied to '${TargetDir}/.bashrc'..."${C_Off}
        
        # Compile and copy bash_aliases
        
        if [ -f bash_aliases ] && [ -f Desktops/${_Desktop}/bash_aliases ] && [ -f perso/perso_aliases ] && [ -f Distrib/${1}/${1}_aliases ];then
            cat bash_aliases Distrib/${1}/${1}_aliases Desktops/${_Desktop}/bash_aliases perso/perso_aliases > ${TargetDir}/.bash_aliases
        elif [ -f bash_aliases ] && [ -f perso/perso_aliases ] && [ -f Distrib/${1}/${1}_aliases ];then
            cat bash_aliases Distrib/${1}/${1}_aliases perso/perso_aliases > ${TargetDir}/.bash_aliases
        elif [ -f bash_aliases ] && [ -f Distrib/${1}/${1}_aliases ];then
            cat bash_aliases Distrib/${1}/${1}_aliases > ${TargetDir}/.bash_aliases
        elif [ -f bash_aliases ];then
            cat bash_aliases > ${TargetDir}/.bash_aliases || return 1
        else echo -e ${BRed}"No aliases file found... Aborting..."${C_Off}
        
        fi
        
        echo ${BGreen}"Bash aliases compiled and copied to '${TargetDir}/.bash_aliases'..."${C_Off}
                
        # Compile and copy bash_functions
        
        if [ -f bash_functions ] && [ -f Distrib/${1}/${1}_functions ] && [ -f Desktops/${_Desktop}/bash_functions ] && [ -f perso/perso_functions];then
                cat bash_functions Distrib/${1}/${1}_functions Desktops/${_Desktop}/bash_functions perso/perso_functions > ${TargetDir}/.bash_functions
        elif [ -f bash_functions ] && [ -f Distrib/${1}/${1}_functions ] && [ -f perso/perso_functions ];then
                cat bash_functions Distrib/${1}/${1}_functions perso/perso_functions > ${TargetDir}/.bash_functions || return 1
        elif [ -f bash_functions ] && [ -f Distrib/${1}/${1}_functions ];then
                cat bash_functions Distrib/${1}/${1}_functions > ${TargetDir}/.bash_functions || return 1
        elif [ -f bash_functions ];then
                cat bash_functions > ${TargetDir}/.bash_functions || return 1
        else echo -e ${BRed}"No functions file found... Aborting..."${C_Off}

        fi
        
        echo -e ${BGreen}"Bash_functions compiled and copied to '${TargetDir}/.bash_functions'..."${C_Off}
                
        # Want to boost bash?
        # Awesome fonts? TODO:
        # Complete bash boost
        # better getopt?
        # Liquidpromt?
        # powerline?

        
        if [ -n "$(ls ${RunDir}/fonts/Terminal/)" ];then 
            ${yad} --text='Do you want to install extras and awesome fonts?'
        fi
        
        if  [ "$?" = "0" ];then
            if [ -f termfont_install.sh ];then
                ${_terminal} -e "/bin/bash termfont_install.sh"
            else echo ${BRed}"No font fonts installation script found, aborting..."${C_Off}
            fi
        fi
    echo -e ${BGreen}'Dot files installed!\nBye!'${C_Off}
    kdialog --title "Bash files installation" --msgbox 'Bash files successfully installed!'
    return 0
}

## /etc files voir peut-être etckeeper?
_etcinstall() {
    _error "We should have ran: rsync -r -x -c -b -i -s etc/ /etc/ || return 1"
    return 0
}

### Git-config
_gitconf() {
    Name=""
    Email=""
    G_Name=$(${_yad} --text='Enter your git user name: ' YourGitUserName)
    if  [ -n ${Name} ];then sed -e "s/NAME/${Name}/g" perso/gitconfig ${TargetDir}/.gitconfig;fi
    G_Email=${_yad} --text "Enter your git user email address: "
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

### TODO: Other dot or save files

# .config dir TODO:and personnal stuff
rsync --remove-source-files .config/ ${HOME}/.config/ && find -type d -empty -delete
return 0
}

# Check if step has been done
_istatus() {
        [ -n "$(grep $1 ${Confile} 2>/dev/null)" ] && echo off || echo on
}

# Create some config/remember file as a ridiculous function for now but should be boosted
ConfigFile() {
        echo "" >> ${Confile}
}

# If no argument given verify what's run and what's not
AskWhat2run() {
# Control what step to do
Steps2do=( $(kdialog --title "What should we do?" --checklist "Choose the step(s) you want to be run: " _postinstall 'Post Installation and update.' $(echo $(_istatus post)) _bashinstall 'Bash files installation' $(echo $(_istatus bash)) _configinstall 'Config files and personnal files restoration.' $(echo $(_istatus perso)) _etcinstall 'System files restoration' $(echo $(_istatus sys)) 2>/dev/null) )
}

### :Script functions #
#######################

###############
### Main Run: #
###############

# Verify input data and variables:
VeriF

# Ask for user to install for:
AskUserName

# Find used distribution:
# GetDistrib || 
DISTRIB_ID=KaOS # While getdistrib doesn't work use Kaos

# Control and apply arguments if any: 
case "$1" in
    "--postinstall" | "-p") 
    if [ -z "$2" ];then
        for Act in "_postinstall _bashinstall  _userinstall _etcinstall" 
        do 
            ${Act} ${DISTRIB_ID} || _error "Errors happened while ${Act}"
        done
    elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
            _postinstall ${DISTRIB_ID} || _error "Errors happened while running post-install process."
    fi 
    ;;
        
    "--bashinstall" | "-b") 
    if [ -z "$2" ];then
        for Act in "_bashinstall  _userinstall _etcinstall"
        do 
            $(${Act}) ${DISTRIB_ID} || _error "Errors happened while ${Act}"
        done 
    elif [ -n "$2" ];then
        _bashinstall ${DISTRIB_ID} || _errorexit "Errors happened while running bashinstall process."
    fi 
    ;;
    
    "--userinstall" | "-u") 
    if [ -z "$2" ];then
        for Act in " _userinstall _etcinstall" 
        do 
            $(${Act}) ${DISTRIB_ID} || _error "Errors happened while ${Act}"
        done 
    elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
        _bashinstall ${DISTRIB_ID} || _errorexit "Errors happened while running userinstall process."
    fi 
    ;;
    
    "--etcinstall" | "-e") 
    if [ -z "$2" ];then
        _etcinstall ${DISTRIB_ID} || _errorexit "Errors happened while running etcinstall process."
    elif [ "$2" = "--only" ] || [ "$2" = "-o" ];then
        _errorexit "You cannot use the --only or -o flag when using --etcinstall or -e one.<br>See this script usage with:<br>$ $0 --help<br>Or<br>$ $0 -h<br>Or<br>$ $0 --usage"
    fi 
    ;;
    
    "") AskWhat2run
            for a in ${Steps2do[@]} 
                    do eval ${a} ${DISTRIB_ID} || _error "Error while ${a}"    
            done ;;
    *) UsageDisplay && _errorexit '<b>Arguments not regognized...</b><br><br>You should look at usage for this script...<br>Running it with --help or -h option.' ;;
esac

exit 0
