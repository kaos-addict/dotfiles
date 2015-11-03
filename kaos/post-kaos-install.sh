#!/bin/bash
# Small personnal script to run just after kaos install

# VARIABLES
Savef=mermouy.dot
Sext=tar.bz2
Source=/media/Remise/save
Wkdir=/tmp

# Gist files to retrieve
Pkgbproto=https://gist.githubusercontent.com/kaos-addict/0a8b0f46713a9dadd4c2/raw/f0a1afb05d7f7a53889bb3847c0f860f1035318a/kaos-pkgbuild-commented-proto

# Extract savefiles
cd $Wkdir
case $Sext in
    tar.bz2) tar -xvjf $Source/$Savef.$Sext || echo "Problem while extracting tar.bz2 savefiles";;
    tar.gz) tar -xvzf $Source/$Savef.$Sext || echo "Problem while extracting tar.gz savefiles";;
    tar.xz) tar -xvJf $Source/$Savef.$Sext || echo "Problem while extracting tar.xz savefiles";;
esac

### Bashfiles
for bf in $(ls bash*)
    do
    bfname=$(basename $bf)
    cp -f $bf $HOME/.$bfname
    chown $USER:users $HOME/.$bfname
    chmod 744 $HOME/.$bfname
done

### TODO: Other dot files

### TODO: confirmation dialog (qarma?)

# .config dir TODO:and personnal stuff
rsync --remove-source-files .config/ $HOME/.config/ && find -type d -empty -delete

### Get bunch of gist files helpers

# KaoS PKGBUILD prototype file
wget $Pkgbproto && kdesu mv kaos-pkgbuild-commented-proto /usr/share/pacman/PKGBUILD.commented.proto
