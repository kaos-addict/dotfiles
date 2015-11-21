#!/bin/bash
# Small personnal script to run just after kaos install

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

cd "${Source}/${Savef}/"
### Bashfiles
for bf in $(ls bash*)
    do
    bfname=$(basename $bf)
    cp -f ${bf} ${HOME}/.${bfname}
    chown ${USER}:users ${HOME}/.${bfname}
    chmod 744 ${HOME}/.${bfname}
done

### TODO: Other dot files

### TODO: confirmation dialog (qarma?)

# .config dir TODO:and personnal stuff
rsync --remove-source-files .config/ ${HOME}/.config/ && find -type d -empty -delete
exit 0