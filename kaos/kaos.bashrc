# Si pas lancée aujourd'hui afficher les nouveauté depuis KaOSx.us
Lafile="$HOME/.config/KnewOS.$(date -I).log"
# If today's file exist or if there's no file of that name, just skip update
# If older ones exist then update & display
if [ -f ${Lafile} ] || [ -z "$(ls $HOME/.config/KnewOS.*.log 2>/dev/null)" ];then
    return 0
else KnewOS
fi
