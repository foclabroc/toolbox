#!/bin/bash
clear

# Demande du mot de passe via dialog
mdp=$(dialog --backtitle "Foclabroc Toolbox" --passwordbox "Mot de passe nécessaire :" 8 40 2>&1 >/dev/tty)

if [[ $? -ne 0 || -z "$mdp" ]]; then
    clear
    echo "Erreur retour menu."
    sleep 3
    exit 0
fi

# URL du script distant
url="https://foclabroc.freeboxos.fr:55973/share/CXyCyAMW0bLI8187/underground_${mdp}.sh"
tmpfile="/tmp/underground_script.sh"

# Téléchargement et exécution
if curl -fsSL "$url" -o "$tmpfile"; then
    chmod +x "$tmpfile"
    dialog --infobox "Mot de passe correct." 5 30
    sleep 1
    bash "$tmpfile"
    rm -f "$tmpfile"
else
    dialog --msgbox "Mot de passe incorrect ou erreur réseau." 8 50
fi

