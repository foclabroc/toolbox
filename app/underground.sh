#!/bin/bash
clear

# Demande du mot de passe via dialog
mdp=$(dialog --backtitle "Foclabroc Toolbox" --inputbox "Mot de passe nécessaire :" 8 40 2>&1 >/dev/tty)

if [[ $? -ne 0 || -z "$mdp" ]]; then
    clear
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé retour menu." 5 30 2>&1 >/dev/tty
    sleep 3
    exit 0
fi

# URL du script distant
url="https://foclabroc.freeboxos.fr:55973/share/CXyCyAMW0bLI8187/underground_${mdp}.sh"
tmpfile="/tmp/underground_script.sh"

# Téléchargement et exécution
if curl -fsSL "$url" -o "$tmpfile"; then
    chmod +x "$tmpfile"
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nMot de passe correct..." 5 30 2>&1 >/dev/tty
    sleep 2
    bash "$tmpfile"
    rm -f "$tmpfile"
else
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nMot de passe incorrect ou erreur réseau.\nRetour menu" 8 50 2>&1 >/dev/tty
fi

