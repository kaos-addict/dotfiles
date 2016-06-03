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

### TODO:
#   Verify internet
#   Remove error outputs
#
### :TODO

# This script is part of public domain so use/modify it as wanted without limitations, commercial use or not...
License='Public Domain'

##########################
### Args & requirements: #
##########################

# If present use first given argument as username, should not be empty as some of following variables are based on username:
[ $# = 1 ] && User=$1 

##########################
### :Args & requirements #
##########################

################
### VARIABLES: #
################

# TODO: These should be detected instead of hardcoded:
Distrib=KaOS
ProgName="$(basename "$0" .sh)"
Dial="/usr/bin/kdialog --title ${ProgName}"
yad="$(which yad) --icon-theme=midna --window-icon=kaos.svg --title=${ProgName} --center --text-align=fill --selectable-labels"
K_Dir="$( cd "$(dirname "$0")" ; pwd -P )"
TargetDir="/home/${User}"
IFile="${TargetDir}/.config/${ProgName}-$(date -I).log"
Cfile="${TargetDir}/.config/${ProgName}.cfg"

# File listing extras packages you want to install:
t_file="${K_Dir}/${Distrib}-pacman-list.txt"
kcpFile="${K_Dir}/${Distrib}-kcp-list.txt"

# Pacman basic options change this if you use another pkg manager (yaourt, pacserve etc...)
_pac="/usr/bin/pacman --noprogressbar"

# Kcp app list (only what we really need for these scripts)
KcPkgListBase=( 'yad' )

# Avoid some xdg errors:
export XDG_RUNTIME_DIR=/tmp/runtime-root

# Needed lib for these scripts to run
Basepkglist=( 'base-devel' 'kcp' 'gtk3' 'hicolor-icon-theme' 'intltool' )

################
### :VARIABLES #
################

#####################
### Utils Functions:#
#####################

# Make copy with .ori backup
cpb() { cp -v $@{,.ori} ;}

## Messages:
# Simple Error:
_error() {
        kdialog --error "$1"
}

# Error message and exit:
_errorexit() {
        kdialog --error "$1" && exit 0;
}

## Actual Pkgs state:
# Simple is it installed?:
appstatus() {
        [ -n "$(${_pac} -Qq $1 2>/dev/null)" ] && echo $1 # If present return pkg name
}

# Same formatted for xdialogs lists:
pstatus() {
        [ -n "$(${_pac} -Qq $1 2>/dev/null)" ] && echo FALSE || echo TRUE
}

# Pkg is from Pacman repos or kcp one?
ostatus() {
    app=$1
    if [ -z "$(echo ${KcpCache[@]} | grep -e "^${app}$" 2>/dev/null)" ];then
        if [ -n "$(${_pac} -Ssq $1 2>/dev/null)" ];then
            echo 'PACMAN octopi-panel'
        else echo 'PIP3 /usr/share/icons/midna/apps/scalable/python-idle.sgv'
        fi
    else echo 'KCP /usr/share/icons/octopi.png'
    fi
}

# Wait for pid to finish
waiton() {
pid=$1
me="$(basename $0)($$):"
if [ -z "$pid" ]
then
    echo "$me a PID is required as an argument" >&2
    exit 2
fi

name=$(ps -p $pid -o comm=)
if [ $? -eq 0 ]
then
    echo "$me waiting for PID $pid to finish ($name)"
    while ps -p $pid > /dev/null; do sleep 1; done;
else
    echo "$me failed to find process with PID $pid" >&2
    exit 1
fi
}

# Naive nb of days since file modified
DayDiff() {
    f_mtime=$(stat -c %Y $1)
    currtime=$(date +%s)
    ddiff=$(( (cur_time - f_mtime) / 86400 ))
    echo ${ddiff}
}

#Kcp cache creation
KcpFileCache() {
# keep kcp database copy as cache
    kdialog --title "${ProgName}" --passivepopup 'Updating kcp packages database. Please wait...' 10 &
    
# File exists
    if [ -f ${Cfile} ];then 
        if [ $(DayDiff ${Cfile}) -gt 7 ];then # Is older then a week warn for update
            ${Dial} --warningyesno "Kcp cache file found but is ${DayDiff} days old.<br>Do you want to update?"
            case $? in
                0) KcpCache=( "$(sudo -u ${User} kcp -lfN | tee ${Cfile})" ) ;; # Online update
                1) KcpCache=( $(cat ${Cfile}) ) ;; # Keep using existing file
                *) _error 'Kcp database update cancelled' ;; # Non standart return
            esac
        elif [[ $(DayDiff ${Cfile}) -gt 0 && $(DayDiff ${Cfile}) -lt 8 ]];then # Is older then a week ask for update
            ${Dial} --yesno "Kcp cache file found but is ${DayDiff} day(s) old.<br>Do you want to update?"
            case $? in
                0) KcpCache=( "$(sudo -u ${User} kcp -lfN | tee ${Cfile})" ) ;;
                1) KcpCache=( "$(cat ${Cfile})" ) ;;
                *) _error 'Kcp database update cancelled' ;;
            esac
        elif [ $(DayDiff ${Cfile}) -eq 0 ];then # File updated today, no update required
            KcpCache=( "$(cat ${Cfile})" )
        else _error 'A problem occured...' 
            return 1
        fi
# File is not present create it
    else KcpCache=( "$(sudo -u ${User} kcp -lfN | tee ${Cfile})" )
    fi
    
# Verify
    if [ -z ${KcpCache} ];then
        _error 'Unable to update Kcp database' && return 1
    else return 0
    fi
}


######################
### :Utils Functions #
######################

#################################
### Update & install Functions: #
#################################

# Very first and complete update
FirstUpdate() {
# TODO: 
# Should work with fifo       Fifo=$(mktemp /tmp/KaOS-restore.XXXXXX)
# Better control of the update/install process

## Update system

konsole --nofork -e "${_pac} --noconfirm -Suyy & mypid=$!"

waiton ${mypid}
echo -e "$(date -I)\nupdate">> ${IFile}
}

PostPkgProcess() {

# Ask for installation
    ${Dial} --yesno "This script need few librairies in order to run.
Some of them may already be present on your system.<br>Here they are:<br>${Basepkglist[*]}<br>Should we install them now?" --yes-label Install --no-label Skip
    if [ $? = 0 ];then
        konsole --nofork -e ${_pac} --needed --noconfirm -S ${Basepkglist[*]}
    else return 1
    fi

# Ask for installing Kcp list from file
    ${Dial} --yesno "This script need one last library to install from Kcp:<br><code> ${KcPkgListBase} </code><br>Should we install them now? (Script will end if not...)" --yes-label Install --no-label Skip
    if [ $? = 0 ];then
# Kcp cache file
        KcpFileCache
# Install needed pkgs
        InstallMiniKcpPkg
    fi
    
# Ask if we install more pkgs    
    ${Dial} --yesno \
"This script uses a file listing packages to install from Kcp:<br>This what this file actually contains: <code> ${Basepkglist[*]} \
</code><br>Do you want to look at these now?" \
--yes-label "Select Pkgs" --no-label Skip 
    [ $? = 0 ] && PkgPostInstall       # Install from file-list
    
# Need Reboot?
    ${Dial} --yesno "System may have been updated, and packages added should we REBOOT now?\n(Not needed if you didn't updated anything or installed just a few packages...)" --yes-label "Reboot" --no-label "Skip"
    [ $? = 0 ] && reboot
    return 0
}

# Verify apps status, do not propose them for install again
ToInstall() {
        
        # All needed for progress bar status
        nbpkg=$(wc -l< ${t_file}) # Number of applications found
        ppb=$(echo "scale=9; 100.0/${nbpkg}" | bc) # Divider
        
        # Keep one non-variable
        pp="${ppb}"
        rm -f /tmp/KaOS-restore.tmp
        
        # Create kcp list cache
        [ -f /tmp/Kcp-list.tmp ] && rm /tmp/Kcp-list.tmp
        sudo -u ${User} kcp -Nl > /tmp/Kcp-list.tmp
        for app in $(tr '\n' ' ' < ${t_file})
        do
                # First echo to file
                echo "$(pstatus ${app}) ${app} ${app} $(ostatus ${app}) " >> /tmp/KaOS-restore.tmp
                # Second to progress bar
                echo "$(pstatus ${app}) ${app} $(ostatus ${app})"
                echo "${pp} ${pp}%: Verify ${app}"
                pp=$(echo "scale=9; ${pp} + ${ppb}" | bc)
        done< ${t_file}
}
        
PkgPostInstall() {
        ToInstall | ${yad} --progress --percentage=1 --auto-close 

# Allow user to select/deselect apps TODO:Make this edit possibly saving file
        Pacpkg=$(${yad} --list --checklist --text="Deselect now applications you don't want to be added to your system: \nAlready installed packages are unchecked, and won't be removed, to remove them do it manually with root privileges like: \npacman -Rsn 'Your packages'" --column="Select" --column="Application" --column=Icon:IMG --column="Origin: " --column="Icon Origin: ":IMG --image=octopi-panel --image-on-top --height 700 --width 500 $(tr '\n' ' ' < /tmp/KaOS-restore.tmp) )

# Update pkgs list with user choices
        paclist=$(grep PACMAN <<<"${Pacpkg}" | sed -e 's/|PACMAN||//g;s/TRUE|//g' | sed 's/|//' | tr '\n' ' ') && \
        kcplist=$(grep KCP <<<"${Pacpkg}" | sed -e 's/|KCP||//g;s/$|//g')
        
        cat >/tmp/testroot.tmp<<PacList
title: 'Installing selected apps from pacman repos' ;; command: echo 'This script should try to manage kcp dependancies, for now, you still have to do it manually... Running kcp with the "-d" option to install pkgs as dependancies for next "-i" (install) pkg.' && ${_pac} --noconfirm --needed -S ${paclist}
PacList

        # Install pacman packages
        [ -n "${paclist}" ] && konsole --nofork --tabs-from-file /tmp/testroot.tmp 2>/dev/null & pid=$!
        
        # Install kcp  packages 
        [ -n "${kcplist}" ] && wait ${pid} && sudo -u ${User} konsole --nofork -e "for app in ${kcplist};do kcp -i ${app};done" & pid=$!
        
        # Keep trace, step has been run
        echo "post" >> ${IFile}
}

AddCustomRepo() {

# Verify folder exists then ask for confimation to enable:
        Repodir=$(grep "Server =" ${K_Dir}/${Distrib}.custom.repo | cut -d "=" -f2 | sed 's# file://##')
        if [ -d ${Repodir} ];then 

# Ask for custom repo file content
            ${yad} --text="A custom repo file has been found as well as a corresponding directory;\n should I add this repo to /etc/pacman.conf?\nYou can also edit it right from here; then click 'Add' button.\nIf you won't need this custum repository addition, just remove the '${K_Dir}/${Distrib}.custom.repo' file" --text-info --filename="${K_Dir}/${Distrib}.custom.repo" --editable >>/etc/pacman.conf
        fi
}

################################
### :Update & Install Functions#
################################

#################
### Main script:#
#################
        
## Run these functions if corresponding files are found:
# If custom repo file is found ask to add it before anything else

[[ -f "${K_Dir}/${Distrib}.custom.repo" && -n $(cat "${K_Dir}/${Distrib}.custom.repo") ]] && AddCustomRepo

# Verify first update has been run

if [ ! -f ${IFile} ] || [ -z "$(grep "update" ${IFile} 2>/dev/null)" ];then
        FirstUpdate
        
    # Else ask to re-run?
else ${Dial} --yesno "It seems that this script first general update has already been run,\ndo you want to run it again?\n(Run this if you didn't upgraded your system recently.)" 
        [ $? = 0 ] && FirstUpdate
fi

# Verify if post-install pkgs from found list have been installed:

if [ -z "$(grep post ${IFile} 2>/dev/null)" ] || [ "$1" = "--postinstall" ];then
        PkgPostInstall # || _errorexit "Error occured while post installing packages."
        
    # Else ask for re-run?
    
else ${Dial} --yesno "It looks like this post-install script has already been run,\nshould we run it again?\n(In case you want use this script to install more applications for example.)"
        if [ $? = 0 ];then
                PkgPostInstall # || _errorexit "Problem occured while installing packages."
        fi
fi

#################
### :Main Script#
#################

exit 0
