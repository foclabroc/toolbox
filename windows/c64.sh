#!/bin/bash

##############################################################################################################
##############################################################################################################
# VARIABLE DU JEU
URL_TELECHARGEMENT="https://github.com/foclabroc/toolbox/releases/download/Fichiers/Celeste64.wsquashfs"
URL_TELECHARGEMENT_KEY=""
CHEMIN_SCRIPT=""
FICHIER_ZIP=""
PORTS_DIR="/userdata/roms/ports"
WIN_DIR="/userdata/roms/windows"
GAME_FILE="Celeste64.wsquashfs"
##############################################################################################################
##############################################################################################################
# VARIABLES GAMELIST
IMAGE_BASE_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/_images"
GAME_NAME="Celeste 64"
GIT_NAME="celeste_64"
DESC="Le retour de Madeline mais en 3D."
DEV="Extremely OK Games"
PUBLISH="Extremely OK Games"
GENRE="Plateforme"
LANG="en"
REGION="eu"
########################################
IMAGE_DIR="$WIN_DIR/images"
VIDEO_DIR="$WIN_DIR/videos"
SCREENSHOT="$IMAGE_DIR/$GIT_NAME-s.png"
WHEEL="$IMAGE_DIR/$GIT_NAME-w.png"
THUMBNAIL="$IMAGE_DIR/$GIT_NAME-b.png"
VIDEO="$VIDEO_DIR/$GIT_NAME-v.mp4"

##############################################################################################################
##############################################################################################################
#XMLSTARLET VARIABLES
GAMELIST_FILE="$WIN_DIR/gamelist.xml"
XMLSTARLET_DIR="/userdata/system/pro/extra"
XMLSTARLET_BIN="$XMLSTARLET_DIR/xmlstarlet"
XMLSTARLET_SYMLINK="/usr/bin/xmlstarlet"
CUSTOM_SH="/userdata/system/custom.sh"
##############################################################################################################

# Fonction de chargement
afficher_barre_progression() {
    (
        echo "10"; sleep 0.5
        mkdir -p "$WIN_DIR"
        echo "20"; sleep 0.5
        curl -L --progress-bar "$URL_TELECHARGEMENT" -o "$WIN_DIR/$GAME_FILE" > /dev/null 2>&1
        echo "60"; sleep 0.5
        if [ -n "$URL_TELECHARGEMENT_KEY" ]; then
            curl -L --progress-bar "$URL_TELECHARGEMENT_KEY" -o "$WIN_DIR/${GAME_FILE}.keys" > /dev/null 2>&1
            echo "70"; sleep 0.5
        fi
        echo "80"; sleep 0.5
        echo "90"; sleep 0.5
        echo "100"; sleep 0.5
    ) |
    dialog --backtitle "Foclabroc Toolbox" --title "Installation de $GAME_NAME" --gauge "\nTéléchargement et installation de $GAME_NAME en cours..." 8 60 0 2>&1 >/dev/tty
}

# Fonction edit gamelist
ajouter_entree_gamelist() {
    (
        echo "5"; sleep 0.3
        mkdir -p "$IMAGE_DIR"
        mkdir -p "$VIDEO_DIR"
        echo "10"; sleep 0.3
        curl -s -L -o "$WHEEL" "$IMAGE_BASE_URL/$GIT_NAME-w.png"
        echo "30"; sleep 0.3
        curl -s -L -o "$SCREENSHOT" "$IMAGE_BASE_URL/$GIT_NAME-s.png"
        echo "50"; sleep 0.3
        curl -s -L -o "$THUMBNAIL" "$IMAGE_BASE_URL/$GIT_NAME-b.png"
        curl -s -L -o "$VIDEO" "$IMAGE_BASE_URL/$GIT_NAME-v.mp4"
        echo "60"; sleep 0.3

        if [ ! -f "$GAMELIST_FILE" ]; then
            echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$GAMELIST_FILE"
        fi

        echo "65"; sleep 0.3

        if [ ! -f "$XMLSTARLET_BIN" ]; then
            mkdir -p "$XMLSTARLET_DIR"
            curl -s -L "https://github.com/foclabroc/toolbox/raw/refs/heads/main/app/xmlstarlet" -o "$XMLSTARLET_BIN"
            chmod +x "$XMLSTARLET_BIN"
            ln -sf "$XMLSTARLET_BIN" "$XMLSTARLET_SYMLINK"
            if [ ! -f "$CUSTOM_SH" ]; then
                echo "#!/bin/bash" > "$CUSTOM_SH"
                chmod +x "$CUSTOM_SH"
            fi
            if ! grep -q "ln -sf $XMLSTARLET_BIN $XMLSTARLET_SYMLINK" "$CUSTOM_SH"; then
                echo "ln -sf $XMLSTARLET_BIN $XMLSTARLET_SYMLINK" >> "$CUSTOM_SH"
            fi
        fi

        echo "80"; sleep 0.3

        xmlstarlet ed -L \
            -s "/gameList" -t elem -n "game" -v "" \
            -s "/gameList/game[last()]" -t elem -n "path" -v "./$GAME_FILE" \
            -s "/gameList/game[last()]" -t elem -n "name" -v "$GAME_NAME" \
            -s "/gameList/game[last()]" -t elem -n "desc" -v "$DESC" \
            -s "/gameList/game[last()]" -t elem -n "image" -v "./images/$GIT_NAME-s.png" \
            -s "/gameList/game[last()]" -t elem -n "video" -v "./videos/$GIT_NAME-v.mp4" \
            -s "/gameList/game[last()]" -t elem -n "marquee" -v "./images/$GIT_NAME-w.png" \
            -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/$GIT_NAME-b.png" \
            -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
            -s "/gameList/game[last()]" -t elem -n "developer" -v "$DEV" \
            -s "/gameList/game[last()]" -t elem -n "publisher" -v "$PUBLISH" \
            -s "/gameList/game[last()]" -t elem -n "genre" -v "$GENRE" \
            -s "/gameList/game[last()]" -t elem -n "lang" -v "$LANG" \
            -s "/gameList/game[last()]" -t elem -n "region" -v "$REGION" \
            "$GAMELIST_FILE"

        echo "95"; sleep 0.3

        curl -s http://127.0.0.1:1234/reloadgames
        echo "100"; sleep 0.3
    ) |
    dialog --backtitle "Foclabroc Toolbox" --title "Edition du gamelist" --gauge "\nAjout images et video au gamelist windows..." 8 60 0 2>&1 >/dev/tty
}

# Exécution
afficher_barre_progression
ajouter_entree_gamelist

# Message de fin
dialog --backtitle "Foclabroc Toolbox" --title "Installation terminée" --msgbox "\n$GAME_NAME a été ajouté dans windows !\n\nPensez à mettre à jour les listes de jeux pour le voir apparaître dans le menu." 10 60 2>&1 >/dev/tty
clear
