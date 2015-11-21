#!/bin/bash
# Edit Pacman.conf and mirrorlist before anything to optimize updates etc...
TargetDir="${HOME}"
K_Dir="$(dirname $0)"
RunDir="$(dirname ${K_Dir})"
Distrib=KaOS

if [ ! -f ${TargetDir}/.config/${Distrib}-post-install ]
then
Dial='kdialog --title "KaOS-post-installation script" --icon=/usr/share/icons/KaOS.svg'
${Dial} --yesno "Edit your pacman and mirrorlist files (you can safely skip this phase if you are in USA)"
        if [ "$?" = "0" ]
        then
                kdesu kate /etc/mirrorlist /etc/pacman.conf
        fi

### Updates 
        _pac="pacman"
        ${_pac} -Suy && touch ${TargetDir}/.config/${Distrib}-post-install
        ${Dial} "msgbox 'You should reboot now to be sure to run an updated system...' --oklabel 'Reboot'" && reboot
fi

ToInstall="$(cat ${K_Dir}/${Distrib}-pacman-list.txt)"
kdialog --checklist "Select or deselect now applications you want to be added to your system: " ${ToInstall}
        