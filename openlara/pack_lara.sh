#!/bin/bash

# ========== Variables globales ==========
NOM_PACK="Pack OpenLara"
URL_ZIP="https://github.com/foclabroc/toolbox/releases/download/Fichiers/openlara.zip"
FICHIER_ZIP="/tmp/openlara.zip"
DEST_DIR="/userdata/roms"
INSTALL_DIR="$DEST_DIR/openlara"
DIALOG_BACKTITLE="Foclabroc Toolbox"
GAME_NAME="OpenLara"
# ========================================

# Boîte de confirmation
dialog --backtitle "$DIALOG_BACKTITLE" --title "$NOM_PACK" \
--yesno "\nScript d'installation du $NOM_PACK.\n\nCela supprimera complètement le dossier $INSTALL_DIR\n\net le remplacera par ce pack.

Souhaitez-vous continuer ?" 15 60 || exit 0

clear

# Suppression de l'ancien dossier
if [ -d "$INSTALL_DIR" ]; then
    dialog --infobox "Suppression de l'ancien dossier $GAME_NAME..." 5 50 2>&1 >/dev/tty
    rm -rf "$INSTALL_DIR"
    sleep 1
fi

# Fonction de téléchargement avec progression et vitesse
telechargement_zip() {
    FILE_PATH="$FICHIER_ZIP"
    FILE_SIZE=$(curl -sIL "$URL_ZIP" | grep -i Content-Length | tail -1 | awk '{print $2}' | tr -d '\r')
    [ -z "$FILE_SIZE" ] && FILE_SIZE=0

    START_TIME=$(date +%s)

    curl -sL -o "$FILE_PATH" "$URL_ZIP" &
    PID_CURL=$!

    (
        while kill -0 $PID_CURL 2>/dev/null; do
            if [ -f "$FILE_PATH" ] && [ "$FILE_SIZE" -gt 0 ]; then
                CURRENT_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
                NOW=$(date +%s)
                ELAPSED=$((NOW - START_TIME))
                [ "$ELAPSED" -eq 0 ] && ELAPSED=1
                SPEED_MO=$(echo "scale=2; $CURRENT_SIZE / $ELAPSED / 1048576" | bc)
                CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
                TOTAL_MB=$((FILE_SIZE / 1024 / 1024))
                PROGRESS_DL=$((CURRENT_SIZE * 100 / FILE_SIZE))
                PROGRESS=$((10 + PROGRESS_DL))
                [ "$PROGRESS" -gt 100 ] && PROGRESS=100

                echo "XXX"
                echo -e "\n\nTéléchargement de $GAME_NAME..."
                echo -e "\nVitesse : ${SPEED_MO} Mo/s | Téléchargé : ${CURRENT_MB} / ${TOTAL_MB} Mo"
                echo "XXX"
                echo "$PROGRESS"
            fi
            sleep 0.5
        done
    ) | dialog --backtitle "$DIALOG_BACKTITLE" --title "Téléchargement" --gauge "" 10 60 0 2>&1 >/dev/tty

    wait $PID_CURL

    if [ ! -s "$FILE_PATH" ]; then
        dialog --msgbox "Erreur : le téléchargement a échoué." 6 50 2>&1 >/dev/tty
        exit 1
    fi
}

# Fonction d’extraction avec progression réelle
extraction_zip() {
    TOTAL_FILES=$(unzip -l "$FICHIER_ZIP" | grep -E "^\s*[0-9]" | wc -l)
    [ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1
    COUNT=0

    (
        unzip -o "$FICHIER_ZIP" -d "$DEST_DIR" | while read -r line; do
            COUNT=$((COUNT + 1))
            PERCENT=$((COUNT * 100 / TOTAL_FILES))
            [ "$PERCENT" -gt 100 ] && PERCENT=100

            echo "XXX"
            echo "$PERCENT"
            echo "Extraction de $GAME_NAME... ($PERCENT %)"
            echo "XXX"
        done
    ) | dialog --backtitle "$DIALOG_BACKTITLE" --title "Décompression" --gauge "" 8 60 0 2>&1 >/dev/tty

    rm -f "$FICHIER_ZIP"
}

# Lancer les étapes
telechargement_zip
extraction_zip

# Message final
dialog --backtitle "$DIALOG_BACKTITLE" --title "Installation terminée" \
--msgbox "\nLe $NOM_PACK a été installé avec succès !" 8 50

clear
exit 0

