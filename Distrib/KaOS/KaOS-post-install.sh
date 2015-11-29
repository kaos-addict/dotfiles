#!/bin/bash
# Edit Pacman.conf and mirrorlist before anything to optimize updates etc...
TargetDir="${HOME}"
K_Dir="$(dirname $0)"
RunDir="$(dirname ${K_Dir})"
Distrib=KaOS
IFile=${TargetDir}/.config/KaOS-restore.log
_pac="pacman"
Dial="kdialog --title=$(basename $0 .sh)"
yad="yad --icon-theme=midna --window-icon=kaos.svg --title=$(basename $0 .sh) --center --text-align=fill --selectable-labels"

# Make copy with .ori backup
cpb() { cp -v $@{,.ori} ;}

### Utils Functions
_error() {
        kdialog --error "$1"
}

_errorexit() {
        kdialog --error "$1" && exit 0;
}

# Verify actual state of pkgs
appstatus() {
        [ -n "$(${_pac} -Qq $1 2>/dev/null)" ] && echo $1 # If present return pkg name
}

pstatus() {
        [ -n "$(${_pac} -Qq $1 2>/dev/null)" ] && echo FALSE || echo TRUE
}

ostatus() {
         [ -z "$(kcp -Nl | grep -e "^$1$" 2>/dev/null)" ] && echo 'PACMAN octopi-panel' || echo 'KCP /usr/share/icons/octopi.png'
}

FirstUpdate() {
# Ask for /etc/pacman.conf & mirrorlist editing
        ${Dial} --yesno "Do you want to edit your pacman and mirrorlist files to make first update faster?\n(you can safely skip this phase if you are in USA)\nThis script will continue when you close the editor."
        if [ "$?" = "0" ]
        then
                cpb /etc/mirrorlist /etc/pacman.conf
                kdesu kate /etc/mirrorlist /etc/pacman.conf
        fi

### Update
# Should work with fifo       Fifo=$(mktemp /tmp/KaOS-restore.XXX)
# TODO: Better control of the update/install process
        kdesu -c "konsole -e mirror-check" -c "konsole -e ${_pac} -Suyy" 
        read -p 'Wait for update to finnish then hit enter:' && echo -e "$(date -I)\nupdate" >> $IFile || _error "Problem encountered while updating system"

# Needed lib for these scripts to run
        Basepkglist="base-devel kcp gtk3 hicolor-icon-theme intltool"
# Ask for installation
        ${Dial} --yesno "This script need these few librairies to run at is best: <p><b>${Basepkglist}</b><p>Should we install them now? (Script will end if not...)" --yes-label "Install" --no-label "Cancel & exit"
        [ $? != 0 ] && exit 0 # Quit if not cause we need these libs!

        # Force Update before install
        kdesu -c "konsole -e  ${_pac} -Syy --noconfirm && ${_pac} -S ${Basepkglist} --needed --noconfirm"
        read -p "Wait for install to finnish then hit enter: " 
         
        # Kcp app list (only what we really need for these scripts)
        KcPkgList="yad"
        
        # Kcp update & apps installation
        kcp -u >/dev/null  && ${Dial} --msgbox="<b>Kcp database has been updated.</b><p>Here are some packages we need to install from kcp: <p><code>${KcPkgList}</code>" --yes-label="Install"
        [ $? != 0 ] && exit 0 # Quit if not cause we need these libs!
        konsole -e "kcp -i ${KcPkgList}" 2>/dev/null && read -p "Wait for install to finnish then hit enter: " 
                
        # Ask for reboot
        ${Dial} --yesno "System has been updated, should we\nREBOOT ?\n(Not needed if you updated just a few packages...)" --yes-label "Reboot" --no-label "Not now"
# would permit:       ${Dial} --textbox ${Fifo} "Once finished you should reboot in order to run an updated system...\nYou will need to run this script again without that first step.' --oklabel 'Reboot'" && rm -vf /tmp/KaOS-restore.* 
        [ $? = 0 ] && reboot
        return 0
}

# Verify apps status, do not propose them for install again
ToInstall() {
        # File containing app list
        t_file="${K_Dir}/${Distrib}-pacman-list.txt"
        # All needed for progress bar status
        nbpkg=$(wc -l< ${t_file}) # Number of applications found
        ppb=$(echo "scale=9; 100.0/${nbpkg}" | bc) # Divider
        # Keep one non-variable
        pp="${ppb}"
        rm -f /tmp/KaOS-restore.tmp
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
        # Verify yad is installed
        $(pacman -Qq yad >/dev/null 2>&1) || _errorexit "This script need <b>yad</b> to be installed.<p>Maybe some problem occured while installing it, please install it manually before running this script again.<p>For this, simply run in a terminal: <p><code>kcp -u && kcp -i yad</code>"
        
        ToInstall | ${yad} --progress --percentage=1 --auto-close 

        # Permit user select and deselect apps
        Pacpkg=$(${yad} --list --checklist --text="Deselect now applications you don't want to be added to your system: \nAlready installed packages are unchecked, and won't be removed, to remove them do it manually with root privileges like: \npacman -R 'Your packages'" --column="Select" --column="Application" --column=Icon:IMG --column="Origin" --column="Icon Origin":IMG --image=octopi-panel --image-on-top --height 700 --width 500 $(tr '\n' ' ' < /tmp/KaOS-restore.tmp) )
        
        paclist=$(echo "${Pacpkg}" | grep PACMAN | sed -e 's/|PACMAN||//g;s/TRUE|//g' | sed 's/|//' | tr '\n' ' ')
        
        kcplist=$(echo "${Pacpkg}" | grep KCP | sed -e 's/|KCP||//g;s/$|//g')
        
        # Install pacman packages
        [ -n "${paclist}" ] && kdesu -c "konsole -e ${_pac} --noconfirm -S $(echo ${paclist})" && read -p "Wait for package install to finish then hit enter: "
        
        # Install kcp  packages
        [ -n "${kcplist}" ] && konsole -e "kcp -s $(echo ${kcplist}) && read -p 'Wait for kcp install to finish then hit enter: '" 
        
        # Keep trace this step has been run
        echo "post" >> ${IFile}
}

AskCustom() {
        ${yad} --text="A custom repo file has been found and the corresponding directory exist too; should I add this repo to /etc/pacman.conf ?" --text-info --filename=${Distrib}/${Distrib}.custom.repo --editable 
}

AddCustomRepo() {
        # Run only if custom file exist
        [ -f "${Distrib}/${Distrib}.custom.repo" ] && AskCustom || return 1
        if [ "$?" = "0" ];then
                cat ${Distrib}/${Distrib}.custom.repo >> /etc/pacman.conf 
        else
                return 1
        fi
}

### Main script launching Functions
# Verify if first update has been run
if [ ! -f ${IFile} ] || [ -z "$(grep "update" ${IFile})" ];then
        FirstUpdate
else
        # Else ask for rerun?
        ${Dial} --yesno "First update has been run do you want to run it again?"
        [ $? = 0 ] && FirstUpdate
fi

# Verify if post installation pkg have been installed
if [ -z "$(grep "post" ${IFile})" ] || [ "$1" = "--postinstall" ];then
        PkgPostInstall || _errorexit "Error occured while post installing packages."
else
        # Else ask for rerun?
        ${Dial} --yesno "This post installation has already been run should we run it again?"
        if [ $? = 0 ];then
                PkgPostInstall || _errorexit "Problem occured while installing packages."
        fi
fi