#!/bin/bash

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

##############################################################################################################
##############################################################################################################
# VARIABLE DU JEU
URL_TELECHARGEMENT="https://github.com/foclabroc/toolbox/releases/download/Fichiers/Pokemon-Uranium.wsquashfs"
URL_TELECHARGEMENT_KEY=""
CHEMIN_SCRIPT=""
FICHIER_ZIP=""
PORTS_DIR="/userdata/roms/ports"
WIN_DIR="/userdata/roms/windows"
GAME_FILE="Pokemon-Uranium.wsquashfs"
##############################################################################################################
##############################################################################################################
# VARIABLES GAMELIST
IMAGE_BASE_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/_images"
GAME_NAME="Pokemon Uranium"
GIT_NAME="pokeura"
DESC="Pokémon Uranium est un fangame gratuit fait dans RPG Maker XP et Pokémon Essentials. Le jeu se déroule dans la région de Tandor, où le joueur doit collecter 8 Badges de Gym afin de participer au Championnat Régional de Tandor. En cours de route, le joueur doit également remplir son PokéDex avec les entrées de plus de 190 espèces différentes de Pokémon."
DEV="Uranium Team"
PUBLISH="Uranium Team"
GENRE="Jeu de role"
LANG="fr"
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
        echo "0"; echo "Initialisation..."
        sleep 0.5
        echo "5"; echo "Création du dossier d'installation..."
        mkdir -p "$WIN_DIR"
        sleep 0.5

        echo "15"; echo "Téléchargement de $GAME_FILE..."

        # Détection de la taille réelle du fichier
        REAL_SIZE=$(wget --spider --server-response "$URL_TELECHARGEMENT" 2>&1 | \
          awk '/Content-Length/ {print $2}' | tail -1)

        # Si la taille n'est pas disponible, on met une estimation de 10 Mo
        if [ -z "$REAL_SIZE" ]; then
            REAL_SIZE=$((10 * 1024 * 1024)) # Estimation 10 Mo
        fi

        CURRENT_SIZE=0

        wget "$URL_TELECHARGEMENT" -O "$WIN_DIR/$GAME_FILE" --progress=dot:mega 2>&1 | \
        stdbuf -oL grep --line-buffered '\.' | \
        awk -v total=$REAL_SIZE '
        {
            downloaded += 102400;  # chaque point ≈ 100K
            percent = int(15 + (downloaded / total) * 55);
            if (percent > 70) percent = 70;
            print percent; print "Téléchargement de " ENVIRON["GAME_NAME"] "...";
            fflush();
        }'

        if [ -n "$URL_TELECHARGEMENT_KEY" ]; then
            echo "70"; echo "Téléchargement des clés..."

            # Détection de la taille des clés
            REAL_KEYS_SIZE=$(wget --spider --server-response "$URL_TELECHARGEMENT_KEY" 2>&1 | \
              awk '/Content-Length/ {print $2}' | tail -1)

            # Si la taille n'est pas disponible, estimation de 1 Mo pour les clés
            if [ -z "$REAL_KEYS_SIZE" ]; then
                REAL_KEYS_SIZE=$((1 * 1024 * 1024)) # Estimation 1 Mo
            fi

            wget "$URL_TELECHARGEMENT_KEY" -O "$WIN_DIR/${GAME_FILE}.keys" --progress=dot:mega 2>&1 | \
            stdbuf -oL grep --line-buffered '\.' | \
            awk -v total=$REAL_KEYS_SIZE '
            {
                downloaded += 102400;
                percent = int(70 + (downloaded / total) * 30);
                if (percent > 100) percent = 100;
                print percent; print "Téléchargement des clés...";
                fflush();
            }'
        fi

        echo "100"; echo "Installation terminée !"
    ) | dialog --backtitle "Foclabroc Toolbox" \
               --title "Installation de $GAME_NAME" \
               --gauge "" 10 60 0
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
dialog --backtitle "Foclabroc Toolbox" --title "Installation terminée" --msgbox "\n$GAME_NAME a été ajouté dans windows !\n\nPensez à mettre à jour les listes de jeux pour le voir apparaître dans le menu." 11 60 2>&1 >/dev/tty
clear
