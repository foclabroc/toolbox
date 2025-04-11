#!/bin/bash

# Répertoire cible
TARGET_DIR="/userdata/system/wine-bottles/windows"

# Fonction pour afficher le menu principal
afficher_menu() {
    # Créer une liste des dossiers cibles
    mapfile -t dossiers < <(find "$TARGET_DIR" -type d \( -name "*.wine" -o -name "*.wsquashfs" -o -name "*.wtgz" \) 2>/dev/null)

    # Vérifier s’il y a des dossiers à afficher
    if [ ${#dossiers[@]} -eq 0 ]; then
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nAucun dossier .wine, .wsquashfs ou .wtgz trouvé." 8 50
        exit 0
    fi

    # Construire la liste pour dialog
    MENU_ITEMS=()
    for i in "${!dossiers[@]}"; do
        MENU_ITEMS+=("$i" "${dossiers[$i]}")
    done

    # Afficher le menu
    CHOIX=$(dialog --backtitle "Foclabroc Toolbox" --clear \
        --title "Sélectionner une bouteille à supprimer" \
        --menu "\nListe des bouteilles :\n " 25 80 10 \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3)

    RETOUR=$?

    if [ $RETOUR -ne 0 ]; then
        clear
        exit 0
    fi

    # Obtenir le chemin réel du dossier sélectionné
    DOSSIER_SELECTIONNE="${dossiers[$CHOIX]}"

    confirmer_suppression "$DOSSIER_SELECTIONNE"
}

# Fonction de confirmation de suppression
confirmer_suppression() {
    DOSSIER="$1"
    dialog --backtitle "Foclabroc Toolbox" --yesno "\nEs-tu sûr de vouloir supprimer la bouteille ?\n\n$DOSSIER" 10 60

    if [ $? -eq 0 ]; then
        rm -rf "$DOSSIER"
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nLa bouteille $DOSSIER a été supprimé avec succès." 9 75
    else
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nSuppression annulée." 7 40
    fi

    # Retour au menu principal
    afficher_menu
}

# Démarrage du script
afficher_menu

clear
