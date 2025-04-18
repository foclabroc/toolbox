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
    IFS=$'\n' DOSSIERS=($(find "$CUSTOM" -mindepth 1 -maxdepth 1 -type d | sort))
    unset IFS

    # Vérifie s'il y a des dossiers
    if [ ${#DOSSIERS[@]} -eq 0 ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun runner trouvé dans $CUSTOM." 7 50 2>&1 >/dev/tty
        sleep 2
        break
    fi

    # Construire la liste pour dialog
    LISTE=()
    for DOSSIER in "${DOSSIERS[@]}"; do
        NOM=$(basename "$DOSSIER")
        TAILLE=$(du -sh "$DOSSIER" | cut -f1)
        DATE=$(stat -c "%y" "$DOSSIER" 2>/dev/null | cut -d'.' -f1)
        LISTE+=("-> [$NOM]" "-->| Taille: $TAILLE | Créé le: $DATE")
    done

    # Ajout de l'option retour
    LISTE+=("<- [Retour]" "Retour au menu précédent")

    # Affiche le menu de sélection
    CHOIX=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Suppression de runner custom" \
        --menu "\nSélectionnez un runner à supprimer :\n " 25 105 15 \
        "${LISTE[@]}" \
        3>&1 1>&2 2>&3)

    # Si annulation ou retour
    if [ -z "$CHOIX" ] || [ "$CHOIX" = "<- [Retour]" ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60 2>&1 >/dev/tty
        sleep 1
        exec bash <(curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh)
    fi

    # Extraire le nom réel sans la déco "-> [ ... ]"
    NOM=$(echo "$CHOIX" | sed 's/^-> \[\(.*\)\]$/\1/')

    # Confirmation
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nVoulez-vous vraiment supprimer le runner '$NOM' ?" 8 50 2>&1 >/dev/tty
    REPONSE=$?
    cd /tmp || exit 1
    if [ "$REPONSE" -eq 0 ]; then
        if [[ -n "$NOM" && "$NOM" != "/" && -d "$CUSTOM/$NOM" ]]; then
            rm -rf "$CUSTOM/$NOM"
            dialog --backtitle "Foclabroc Toolbox" --infobox "\nLe Runner '$NOM' a été supprimé." 6 50 2>&1 >/dev/tty
            sleep 2
        else
            dialog --backtitle "Foclabroc Toolbox" --infobox "\nSuppression échouée ou dossier invalide." 6 50 2>&1 >/dev/tty
            sleep 3
        fi
    else
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nSuppression annulée." 6 50 2>&1 >/dev/tty
        sleep 1
    fi
done

clear
exit 0