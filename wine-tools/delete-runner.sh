#!/bin/bash

# Chemin des dossiers à lister
CUSTOM="/userdata/system/wine/custom"

# Vérifie si le dossier existe
if [ ! -d "$CUSTOM" ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "Le dossier $CUSTOM n'existe pas." 7 50 2>&1 >/dev/tty
    clear
    exit 1
fi

while true; do
    # Récupère la liste des dossiers
    DOSSIERS=($(find "$CUSTOM" -mindepth 1 -maxdepth 1 -type d | sort))

    # Vérifie s'il y a des dossiers
    if [ ${#DOSSIERS[@]} -eq 0 ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "Aucun runner trouvé dans $CUSTOM." 7 50 2>&1 >/dev/tty
        break
    fi

    # Préparer la liste pour dialog
    LISTE=()
    for DOSSIER in "${DOSSIERS[@]}"; do
        NOM=$(basename "$DOSSIER")
        LISTE+=("$NOM" "")
    done

    # Affiche le menu de sélection
    CHOIX=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Suppression de runner custom" \
        --menu "\nSélectionnez un runner à supprimer :\n" 25 80 15 \
        "${LISTE[@]}" \
        3>&1 1>&2 2>&3 2>&1 >/dev/tty)

    # Si annulation (ESC ou bouton Annuler)
    if [ -z "$CHOIX" ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60 2>&1 >/dev/tty
        sleep 1
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
        clear
        exit 0
    fi

    # Confirmation
    dialog --yesno "Voulez-vous vraiment supprimer le dossier '$CHOIX' ?" 7 50 2>&1 >/dev/tty
    REPONSE=$?

    if [ "$REPONSE" -eq 0 ]; then
        rm -rf "$CUSTOM/$CHOIX"
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nLe Runner '$CHOIX' a été supprimé." 6 50 2>&1 >/dev/tty
		sleep 2
    else
        dialog --backtitle "Foclabroc Toolbox" --infobox "Suppression annulée." 6 50 2>&1 >/dev/tty
		sleep 1
    fi
done

clear
exit 0
