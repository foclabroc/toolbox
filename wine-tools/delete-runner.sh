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
    # Récupère la liste des dossiers avec gestion des espaces
    IFS=$'\n' DOSSIERS=($(find "$CUSTOM" -mindepth 1 -maxdepth 1 -type d | sort))
    unset IFS

    # Vérifie s'il y a des dossiers
    if [ ${#DOSSIERS[@]} -eq 0 ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun runner trouvé dans $CUSTOM." 7 50 2>&1 >/dev/tty
        break
    fi

    # Préparer la liste pour dialog
    LISTE=()
    NUMERO=1
    for DOSSIER in "${DOSSIERS[@]}"; do
        NOM=$(basename "$DOSSIER")
        TAILLE=$(du -sh "$DOSSIER" | cut -f1)
        DATE=$(stat -c "%y" "$DOSSIER" 2>/dev/null | cut -d'.' -f1)
        LISTE+=("$NUMERO $NOM" "-->|Taille: $TAILLE | Créé le: $DATE")
        ((NUMERO++))
    done

    # Ajout de l'option retour
    LISTE+=("Retour" "Retour au menu précédent")

    # Affiche le menu de sélection
    CHOIX=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Suppression de runner custom" \
        --menu "\nSélectionnez un runner à supprimer :\n " 25 95 15 \
        "${LISTE[@]}" \
        3>&1 1>&2 2>&3)

    # Si annulation ou retour
    if [ -z "$CHOIX" ] || [ "$CHOIX" = "Retour" ]; then
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60 2>&1 >/dev/tty
        sleep 1
        exec bash <(curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh)
    fi

    # Extraire le numéro de la sélection (si applicable)
    if [[ "$CHOIX" =~ ^[0-9]+$ ]]; then
        DOSSIER_SELECTIONNE="${DOSSIERS[$CHOIX-1]}"
        NOM=$(basename "$DOSSIER_SELECTIONNE")
    else
        DOSSIER_SELECTIONNE="$CHOIX"
    fi

    # Confirmation
    dialog --yesno "\nVoulez-vous vraiment supprimer le dossier '$NOM' ?" 8 50 2>&1 >/dev/tty
    REPONSE=$?

    if [ "$REPONSE" -eq 0 ]; then
        if [[ -n "$DOSSIER_SELECTIONNE" && -d "$DOSSIER_SELECTIONNE" ]]; then
            rm -rf "$DOSSIER_SELECTIONNE"
            dialog --backtitle "Foclabroc Toolbox" --infobox "\nLe Runner '$NOM' a été supprimé." 6 50 2>&1 >/dev/tty
            sleep 2
        else
            dialog --backtitle "Foclabroc Toolbox" --msgbox "\nSuppression échouée ou dossier invalide." 6 50 2>&1 >/dev/tty
        fi
    else
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nSuppression annulée." 6 50 2>&1 >/dev/tty
        sleep 1
    fi
done

clear
exit 0
