#!/bin/bash

# Avertissement initial
dialog --backtitle "Foclabroc Toolbox" --title "ATTENTION !" --yesno "\n\
Attention ! Ce script va faire un listing de toutes les bouteilles Wine de vos jeux Windows disponibles dans /system/wine-bottle/windows.\n\n\
Vous pourrez ensuite supprimer, avec confirmation, celles dont vous n'avez plus besoin.\n\n\
Soyez sûr de votre choix car les bouteilles contiennent les paramètres et sauvegardes de vos jeux Windows.\n\
La suppression est irréversible.\n\n\
Continuer ?" 18 70 2>&1 >/dev/tty

if [ $? -ne 0 ]; then
    clear
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé.\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 0
fi

# Répertoire cible
TARGET_DIR="/userdata/system/wine-bottles/windows"

# Fonction pour afficher le menu principal
afficher_menu() {
    # Créer une liste des dossiers cibles
    mapfile -t dossiers < <(find "$TARGET_DIR" -type d \( -name "*.wine" -o -name "*.wsquashfs" -o -name "*.wtgz" \) 2>/dev/null)

    # Vérifier s’il y a des dossiers à afficher
    if [ ${#dossiers[@]} -eq 0 ]; then
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nAucun dossier .wine, .wsquashfs ou .wtgz trouvé.\nRetour au menu Wine Tools..." 8 50 2>&1 >/dev/tty
        sleep 2
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
        exit 1
    fi

    # Construire la liste pour dialog
    MENU_ITEMS=()
    for i in "${!dossiers[@]}"; do
        MENU_ITEMS+=("$i" "${dossiers[$i]}")
    done

    # Afficher le menu
    CHOIX=$(dialog --backtitle "Foclabroc Toolbox" --clear \
        --title "Sélectionner une bouteille à supprimer" \
        --menu "\nListe des bouteilles :\n " 25 105 10 \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3)

    RETOUR=$?

    if [ $RETOUR -ne 0 ]; then
        clear
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
        sleep 2
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
        exit 1
    fi

    # Obtenir le chemin réel du dossier sélectionné
    DOSSIER_SELECTIONNE="${dossiers[$CHOIX]}"

    confirmer_suppression "$DOSSIER_SELECTIONNE"
}

# Fonction de confirmation de suppression
confirmer_suppression() {
    DOSSIER="$1"
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nEs-tu sûr de vouloir supprimer la bouteille ?\n\n$DOSSIER" 10 60 2>&1 >/dev/tty

    if [ $? -eq 0 ]; then
        rm -rf "$DOSSIER"
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nLa bouteille $DOSSIER a été supprimé avec succès." 8 75 2>&1 >/dev/tty
    else
        dialog --backtitle "Foclabroc Toolbox" --msgbox "\nSuppression annulée." 7 40 2>&1 >/dev/tty
    fi

    # Retour au menu principal
    afficher_menu
}

# Démarrage du script
afficher_menu

clear
