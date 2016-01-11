#!/bin/bash
# Simple install script to be able to install and Restore My System in easy line
Run_Dir=$HOME/.tmp
mkdir -p ${Run_Dir}
Sc_Name=$(basename $0 .sh)
cat> ${Run_Dir}/install.sh <<EOF
git clone https://github.com/Mermouy/RestoreMySystem
cd RestoreMySystem/
sudo bash -c RestoreMySystem.sh
EOF

chmod +x ${Run_Dir}/install.sh
bash -c ${Run_Dir}/install.sh && echo "'Restore My System' has been downloaded, run it like ./RestoreMySystem.sh --help to get all availables options."
exit 0