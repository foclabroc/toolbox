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
        echo "0 - Initialisation..."
        sleep 0.2
        echo "5 - Création du dossier d'installation..."
        mkdir -p "$WIN_DIR"
        sleep 0.2
        echo "15 - Téléchargement de $GAME_FILE..."

        curl -L "$URL_TELECHARGEMENT" -o "$WIN_DIR/$GAME_FILE" 2>&1 | \
        grep --line-buffered "%" | \
        sed -u -e "s/\r//g" | \
        awk '{
            match($0, /([0-9]+)%/, m);
            if (m[1] != "") {
                # Interpolation de 15% à 70%
                p = int(15 + (m[1] * 0.55 / 100));
                print p " - Téléchargement de " ENVIRON["GAME_NAME"] "...";
            }
        }'

        if [ -n "$URL_TELECHARGEMENT_KEY" ]; then
            echo "70 - Téléchargement des clés..."

            curl -L "$URL_TELECHARGEMENT_KEY" -o "$WIN_DIR/${GAME_FILE}.keys" 2>&1 | \
            grep --line-buffered "%" | \
            sed -u -e "s/\r//g" | \
            awk '{
                match($0, /([0-9]+)%/, m);
                if (m[1] != "") {
                    # Interpolation de 70% à 100%
                    p = int(70 + (m[1] * 0.30 / 100));
                    print p " - Téléchargement des clés...";
                }
            }'
        else
            echo "100 - Terminé."
        fi

    ) | dialog --backtitle "Foclabroc Toolbox" \
               --title "Installation de $GAME_NAME" \
               --gauge "\nTéléchargement et installation de $GAME_NAME en cours..." 10 60 0
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
