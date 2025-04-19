#!/bin/bash

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

##############################################################################################################
##############################################################################################################
# VARIABLE DU JEU
URL_TELECHARGEMENT="https://github.com/foclabroc/toolbox/releases/download/Fichiers/SuperTuxKart.wsquashfs"
URL_TELECHARGEMENT_KEY=""
CHEMIN_SCRIPT=""
FICHIER_ZIP=""
PORTS_DIR="/userdata/roms/ports"
WIN_DIR="/userdata/roms/windows"
GAME_FILE="SuperTuxKart.wsquashfs"
GAME_FILE_FINAL="SuperTuxKart.wsquashfs"
INFO_MESSAGE="\n\n!Utiliser le runner WINE-TKG pour le lancement!"
##############################################################################################################
##############################################################################################################
# VARIABLES GAMELIST
IMAGE_BASE_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/_images"
GAME_NAME="Super Tux Kart"
GIT_NAME="supertuxkart"
DESC="Karts. Nitro. Action ! SuperTuxKart est un jeu de karting libre en 3D avec une grande diversité de personnages, de pistes, et de modes de jeu. En mode histoire, vous devrez affonter le démon Nolok, et le battre pour sauver une fois de plus la reine des mascottes ! Vous pourrez courir contre l’ordinateur. Vous pourrez aussi courir, vous battre ou jouer au football vos amis (8 maximum) ou contre un ordinateur, jouer sur un réseau local ou en ligne avec d’autres joueurs partout dans le monde."
DEV="SuperTuxKart Development Team"
PUBLISH="SuperTuxKart Development Team"
GENRE="Course"
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
    TMP_FILE=$(mktemp)

    FILE_PATH="$WIN_DIR/$GAME_FILE"
    # Vérification et suppression du fichier s'il existe déjà
    if [ -f "$FILE_PATH" ]; then
        rm -f "$FILE_PATH"
        echo "Fichier existant supprimé : $FILE_PATH"
    fi

    (
        for i in {5..19..1}; do
            echo "$i"; sleep 0.1
        done
        mkdir -p "$WIN_DIR"

        # Récupération de la taille totale du fichier
        FILE_SIZE=$(curl -sIL "$URL_TELECHARGEMENT" | grep -i Content-Length | tail -1 | awk '{print $2}' | tr -d '\r')

        # Téléchargement réel avec suivi des redirections
        curl -sL "$URL_TELECHARGEMENT" -o "$FILE_PATH" &
        PID_CURL=$!

        # Affichage de la progression
		START_TIME=$(date +%s)

		while kill -0 $PID_CURL 2>/dev/null; do
			if [ -f "$FILE_PATH" ]; then
				CURRENT_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
				NOW=$(date +%s)
				ELAPSED=$((NOW - START_TIME))
				[ "$ELAPSED" -eq 0 ] && ELAPSED=1  # éviter division par 0
				SPEED=$((CURRENT_SIZE / ELAPSED)) # octets/seconde
				SPEED_KB=$((SPEED / 1024))
				SPEED_MB=$((SPEED_KB / 1024))

				# Conversion Mo
				CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
				TOTAL_MB=$((FILE_SIZE / 1024 / 1024))

				if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -gt 0 ]; then
					PROGRESS=$((CURRENT_SIZE * 40 / FILE_SIZE)) # 40 pts d'écart
					PROGRESS=$((20 + PROGRESS))
					[ "$PROGRESS" -gt 60 ] && PROGRESS=60

					echo "XXX"
					echo -e "\n\nTéléchargement de $GAME_FILE..."
					echo -e "\nVitesse : ${SPEED_KB} ko/s | ${CURRENT_MB} / ${TOTAL_MB} Mo"
					echo "XXX"
					echo "$PROGRESS"
				fi
			fi
			sleep 0.5
		done

        wait $PID_CURL

        # Décompression automatique si .zip
        if [[ "$FILE_PATH" == *.zip ]]; then
		    echo "XXX"
			echo -e "\n\nDécompression de $GAME_FILE..."
			echo "XXX"
            unzip -o "$FILE_PATH" -d "$WIN_DIR" >/dev/null 2>&1
            rm -f "$FILE_PATH"
        fi

        for i in {61..70..1}; do
            echo "$i"; sleep 0.1
        done

        if [ -n "$URL_TELECHARGEMENT_KEY" ]; then
		    echo "XXX"
			echo -e "\n\nTélechargement du pad2key..."
			echo "XXX"
            curl -L --progress-bar "$URL_TELECHARGEMENT_KEY" -o "$WIN_DIR/${GAME_FILE}.keys" > /dev/null 2>&1
            echo "70"; sleep 1
        fi

        for i in {71..100..1}; do
            echo "$i"; sleep 0.1
        done
    ) |
    dialog --backtitle "Foclabroc Toolbox" \
           --title "Installation de $GAME_NAME" \
           --gauge "\nTéléchargement et installation de $GAME_NAME en cours..." 9 60 0 \
           2>&1 >/dev/tty

    rm -f "$TMP_FILE"
}




# Fonction edit gamelist
ajouter_entree_gamelist() {
    (
        for i in {1..50..2}; do
            echo "$i"; sleep 0.1
        done
        mkdir -p "$IMAGE_DIR"
        mkdir -p "$VIDEO_DIR"
        curl -s -L -o "$WHEEL" "$IMAGE_BASE_URL/$GIT_NAME-w.png"
        echo "51"; sleep 0.1
        curl -s -L -o "$SCREENSHOT" "$IMAGE_BASE_URL/$GIT_NAME-s.png"
        echo "52"; sleep 0.1
        curl -s -L -o "$THUMBNAIL" "$IMAGE_BASE_URL/$GIT_NAME-b.png"
        echo "53"; sleep 0.1
        curl -s -L -o "$VIDEO" "$IMAGE_BASE_URL/$GIT_NAME-v.mp4"
        for i in {54..64..2}; do
            echo "$i"; sleep 0.1
        done

        if [ ! -f "$GAMELIST_FILE" ]; then
            echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$GAMELIST_FILE"
        fi

        echo "65"; sleep 0.1

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

        for i in {66..94..2}; do
            echo "$i"; sleep 0.1
        done

        xmlstarlet ed -L \
            -s "/gameList" -t elem -n "game" -v "" \
            -s "/gameList/game[last()]" -t elem -n "path" -v "./$GAME_FILE_FINAL" \
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

        for i in {95..99..2}; do
            echo "$i"; sleep 0.1
        done
        curl -s http://127.0.0.1:1234/reloadgames
        echo "100"; sleep 0.2
    ) |
    dialog --backtitle "Foclabroc Toolbox" --title "Edition du gamelist" --gauge "\nAjout images et video au gamelist windows..." 8 60 0 2>&1 >/dev/tty
}

# Exécution
afficher_barre_progression
ajouter_entree_gamelist

# Message de fin
dialog --backtitle "Foclabroc Toolbox" --title "Installation terminée" --msgbox "\n$GAME_NAME a été ajouté dans windows !\n\nPensez à mettre à jour les listes de jeux pour le voir apparaître dans le menu. $INFO_MESSAGE" 12 60 2>&1 >/dev/tty
clear
