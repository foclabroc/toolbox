#!/bin/bash

# Définition des variables
URL_TELECHARGEMENT="https://github.com/foclabroc/toolbox/releases/download/Fichiers/Celeste64.wsquashfs"
CHEMIN_SCRIPT=""
FICHIER_ZIP=""
PORTS_DIR="/userdata/roms/ports"
WIN_DIR="/userdata/roms/windows"
#gamelist
IMAGE_BASE_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/_images"
GAME_NAME="Celeste 64"
GIT_NAME="celeste_64"
IMAGE_DIR="$WIN_DIR/images"
VIDEO_DIR="$WIN_DIR/videos"
GAME_FILE="Celeste64.wsquashfs"
SCREENSHOT="$IMAGE_DIR/$GIT_NAME-s.png"
WHEEL="$IMAGE_DIR/$GIT_NAME-w.png"
THUMBNAIL="$IMAGE_DIR/$GIT_NAME-b.jpg"
VIDEO="$VIDEO_DIR/$GIT_NAME-v.mp4"

GAMELIST_FILE="$WIN_DIR/gamelist.xml"
XMLSTARLET_DIR="/userdata/system/pro/extra"
XMLSTARLET_BIN="$XMLSTARLET_DIR/xmlstarlet"
XMLSTARLET_SYMLINK="/usr/bin/xmlstarlet"
CUSTOM_SH="/userdata/system/custom.sh"

# Fonction de chargement
afficher_barre_progression() {
    (
        echo "10"; sleep 0.5
        mkdir -p "$WIN_DIR"
        echo "20"; sleep 0.5
        curl -L --progress-bar "$URL_TELECHARGEMENT" -o "$WIN_DIR/GAME_FILE" > /dev/null 2>&1
        echo "60"; sleep 0.5
        #unzip -o "$FICHIER_ZIP" -d "$WIN_DIR" > /dev/null 2>&1
        echo "80"; sleep 0.5
        #rm "$FICHIER_ZIP"
        echo "90"; sleep 0.5
        echo "100"; sleep 0.5
    ) |
    dialog --backtitle "Foclabroc Toolbox" --title "Installation de $GAME_NAME" --gauge "\nTéléchargement et installation en cours..." 8 60 0 2>&1 >/dev/tty
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
        curl -s -L -o "$THUMBNAIL" "$IMAGE_BASE_URL/$GIT_NAME-b.jpg"
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
            -s "/gameList/game[last()]" -t elem -n "desc" -v "Le retour de Madeline mais en 3D." \
            -s "/gameList/game[last()]" -t elem -n "developer" -v "Extremely OK Games" \
            -s "/gameList/game[last()]" -t elem -n "publisher" -v "Extremely OK Games" \
            -s "/gameList/game[last()]" -t elem -n "genre" -v "Plateforme" \
            -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
            -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
            -s "/gameList/game[last()]" -t elem -n "lang" -v "en" \
            -s "/gameList/game[last()]" -t elem -n "image" -v "./images/$GIT_NAME-s.png" \
            -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/$GIT_NAME-w.png" \
            -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/$GIT_NAME-b.jpg" \
            -s "/gameList/game[last()]" -t elem -n "video" -v "./videos/$GIT_NAME-v.mp4" \
            "$GAMELIST_FILE"

        echo "95"; sleep 0.3

        curl -s http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
        echo "100"; sleep 0.3
    ) |
    dialog --backtitle "Foclabroc Toolbox" --title "Edition du gamelist" --gauge "\nAjout images et video au gamelist windows..." 8 60 0 2>&1 >/dev/tty
}

# Exécution
afficher_barre_progression
ajouter_entree_gamelist

# Message de fin
dialog --backtitle "Foclabroc Toolbox" --title "Installation terminée" --msgbox "\nCeleste64 a été ajouté dans windows !\n\nPensez à mettre à jour vos gamelists pour le voir apparaître dans le menu." 10 50 2>&1 >/dev/tty

clear
