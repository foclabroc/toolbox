#!/bin/bash
# =====================================================================
#  NFS Underground 2 Revived (nfsu2.xyz) pour Batocera x86_64
#  Installe un Chromium portable (ungoogled-chromium AppImage, extrait)
#  + un port lancé en mode kiosk avec WebGPU (Vulkan).
#
#  Menu          :  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/nfsu2/nfsu2.sh | bash
#  Désinstaller  :  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/nfsu2/nfsu2.sh | bash -s uninstall
#  by foclabroc
# =====================================================================

# ========== Variables globales ==========
NOM_PACK="NFS Underground 2 Revived"
DIALOG_BACKTITLE="Foclabroc Toolbox"
# Dossier caché dans ports : le "." empêche ES de lister le contenu de Chromium
APP_DIR="/userdata/roms/ports/.nfsu2"
OLD_DIRS="/userdata/roms/ports/nfsu2 /userdata/system/pro/nfsu2"
BROWSER_DIR="$APP_DIR/chromium"
LIBS_DIR="$APP_DIR/libs"
PROFILE_DIR="$APP_DIR/profile"
PORT_NAME="NFS Underground 2 Revived"
PORT_SH="/userdata/roms/ports/${PORT_NAME}.sh"
PORT_KEYS="${PORT_SH}.keys"
GAME_URL="https://nfsu2.xyz/"
GH_API="https://api.github.com/repos/ungoogled-software/ungoogled-chromium-portablelinux/releases/latest"
TMP_DIR="/userdata/roms/ports/.nfsu2_tmp"
LOG_FILE="/userdata/system/logs/nfsu2.log"

GAMELIST="/userdata/roms/ports/gamelist.xml"
GAME_PATH="./${PORT_NAME}.sh"
MEDIA_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/nfsu2/extra"
MEDIA_FILES="NFSU2-screenshot.jpg NFSU2-wheel.png NFSU2-cartridge.jpg"
OSK_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/nfsu2/osk"
OSK_FILES="manifest.json main_world.js padmap.js osk.js bg.js"
XMLSTARLET_BIN="/userdata/system/pro/extra/xmlstarlet"
XMLSTARLET_URL="https://github.com/foclabroc/toolbox/raw/refs/heads/main/app/xmlstarlet"
# ========================================

[ -f /userdata/system/pro/extra/.dialogrc ] && export DIALOGRC=/userdata/system/pro/extra/.dialogrc

# ---------------------------------------------------------------------
# Helpers dialog
d_info() { dialog --backtitle "$DIALOG_BACKTITLE" --title "$NOM_PACK" --infobox "\n$1" 7 60 2>&1 >/dev/tty; }
d_msg()  { dialog --backtitle "$DIALOG_BACKTITLE" --title "${2:-$NOM_PACK}" --msgbox "\n$1" "${3:-10}" 64 2>&1 >/dev/tty; }
d_fail() {
    rm -rf "$TMP_DIR"
    d_msg "$1" "Erreur" 9
    clear; exit 1
}

reload_es() { curl -s -m3 http://127.0.0.1:1234/reloadgames >/dev/null 2>&1; }

is_installed() { [ -f "$PORT_SH" ] && [ -d "$APP_DIR" ]; }

# ---------------------------------------------------------------------
# Gamelist (même méthode que les autres paquets de la toolbox)
ensure_xmlstarlet() {
    if [ ! -f "$XMLSTARLET_BIN" ]; then
        mkdir -p "$(dirname "$XMLSTARLET_BIN")"
        curl -sL "$XMLSTARLET_URL" -o "$XMLSTARLET_BIN"
        chmod +x "$XMLSTARLET_BIN"
    fi
    ln -sf "$XMLSTARLET_BIN" /usr/bin/xmlstarlet
}

remove_gamelist_entry() {
    [ -f "$GAMELIST" ] && xmlstarlet ed -L -d "/gameList/game[path=\"$GAME_PATH\"]" "$GAMELIST" 2>/dev/null
}

add_gamelist_entry() {
    mkdir -p /userdata/roms/ports/images /userdata/roms/ports/videos "$APP_DIR"
    for F in $MEDIA_FILES; do
        curl -sL --fail -o "/userdata/roms/ports/images/$F" "$MEDIA_URL/$F"
    done
    curl -sL --fail -o "/userdata/roms/ports/videos/NFSU2-video.mp4" "$MEDIA_URL/NFSU2-video.mp4"
    ensure_xmlstarlet

    # Script séparé : ES réécrit gamelist.xml depuis sa mémoire à la fin de chaque
    # port (toolbox comprise). Il faut donc éditer quand plus rien ne tourne.
    cat > "$APP_DIR/gamelist.sh" <<EOF
#!/bin/bash
# Ajoute/complète la fiche NFSU2 dans le gamelist des ports (Foclabroc Toolbox)
# --wait : attend la fin du port en cours (lancé depuis ES)
GAMELIST="$GAMELIST"
G='/gameList/game[path="$GAME_PATH"]'

if [ "\$1" = "--wait" ]; then
    for i in \$(seq 1 900); do
        pgrep -f "emulatorlauncher|batocera-launch" >/dev/null || break
        sleep 2
    done
    sleep 5   # laisse ES finir de sauvegarder ses stats
fi

[ -f "\$GAMELIST" ] || echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "\$GAMELIST"

# Mise à jour sur place : l'entrée créée par ES (playcount, gametime...) est conservée
if [ "\$(xmlstarlet sel -t -v "count(\$G)" "\$GAMELIST" 2>/dev/null)" = "0" ]; then
    xmlstarlet ed -L -s "/gameList" -t elem -n "game" -v "" \\
        -s "/gameList/game[last()]" -t elem -n "path" -v "$GAME_PATH" "\$GAMELIST"
fi

set_field() {
    xmlstarlet ed -L -d "\$G/\$1" -s "\$G" -t elem -n "\$1" -v "\$2" "\$GAMELIST"
}
set_field name "Need for Speed Underground 2 Revived"
set_field desc "Need for Speed: Underground 2 (2004) dans sa version Revived, le code du jeu PC recompilé pour le navigateur (WebGPU) par un projet fan. Course de rue nocturne dans la ville de Bayview : tuning poussé, free roam, drift, drag, URL et Street X. Jusqu'à 120 fps en écran large, support manette et volant, sauvegardes en ligne et courses Online en free roam avec tes amis et ton crew. Connexion Internet obligatoire. Quitter : Hotkey + Start. Projet fan non affilié à Electronic Arts."
set_field developer "EA Black Box"
set_field publisher "Electronic Arts"
set_field genre "Course"
set_field players "4+"
set_field releasedate "20041109T000000"
set_field rating "0.90"
set_field region "eu"
set_field lang "fr"
set_field image "./images/NFSU2-screenshot.jpg"
set_field wheel "./images/NFSU2-wheel.png"
set_field thumbnail "./images/NFSU2-cartridge.jpg"
set_field video "./videos/NFSU2-video.mp4"

curl -s -m3 http://127.0.0.1:1234/reloadgames >/dev/null 2>&1
EOF
    chmod +x "$APP_DIR/gamelist.sh"

    if pgrep -f "emulatorlauncher|batocera-launch" >/dev/null; then
        # Lancé depuis la toolbox (port) : édition différée, détachée de l'xterm
        setsid nohup bash "$APP_DIR/gamelist.sh" --wait >/dev/null 2>&1 < /dev/null &
        GAMELIST_DEFERRED=1
    else
        bash "$APP_DIR/gamelist.sh"
    fi
}

# ---------------------------------------------------------------------
# Téléchargement avec jauge (même principe que le Pack Music)
telechargement() {
    local URL="$1" FILE_PATH="$2" LABEL="$3"
    local FILE_SIZE START_TIME PID_CURL
    FILE_SIZE=$(curl -sIL "$URL" | grep -i '^content-length' | tail -1 | awk '{print $2}' | tr -d '\r')
    [ -z "$FILE_SIZE" ] && FILE_SIZE=0
    START_TIME=$(date +%s)

    curl -sL --fail -o "$FILE_PATH" "$URL" &
    PID_CURL=$!

    (
        while kill -0 $PID_CURL 2>/dev/null; do
            if [ -f "$FILE_PATH" ] && [ "$FILE_SIZE" -gt 0 ]; then
                CURRENT_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
                ELAPSED=$(( $(date +%s) - START_TIME )); [ "$ELAPSED" -eq 0 ] && ELAPSED=1
                SPEED_MO=$(awk -v s="$CURRENT_SIZE" -v t="$ELAPSED" 'BEGIN{printf "%.2f", s/t/1048576}')
                PROGRESS=$((CURRENT_SIZE * 100 / FILE_SIZE)); [ "$PROGRESS" -gt 100 ] && PROGRESS=100
                echo "XXX"
                echo "$PROGRESS"
                echo -e "\nTéléchargement de $LABEL..."
                echo -e "\nVitesse : ${SPEED_MO} Mo/s | Progression : $((CURRENT_SIZE / 1048576)) / $((FILE_SIZE / 1048576)) Mo"
                echo "XXX"
            fi
            sleep 0.3
        done
    ) | dialog --backtitle "$DIALOG_BACKTITLE" --title "Téléchargement" --gauge "\nConnexion..." 10 64 0 2>&1 >/dev/tty

    wait $PID_CURL
}

# ---------------------------------------------------------------------
uninstall() {
    dialog --backtitle "$DIALOG_BACKTITLE" --title "Désinstallation" --yesno \
"\nSupprimer $NOM_PACK ?\n\nLe navigateur, le port, les médias et l'entrée gamelist seront retirés.\n\nAttention : les sauvegardes locales du profil navigateur seront perdues (pense à « Download backup » dans le menu du jeu avant)." 14 64 2>&1 >/dev/tty || return

    d_info "Désinstallation en cours..."
    pkill -f "$PROFILE_DIR" 2>/dev/null
    rm -rf "$APP_DIR" "$TMP_DIR"
    rm -f "$PORT_SH" "$PORT_KEYS"
    for F in $MEDIA_FILES; do rm -f "/userdata/roms/ports/images/$F"; done
    rm -f /userdata/roms/ports/videos/NFSU2-video.mp4
    command -v xmlstarlet >/dev/null 2>&1 || ensure_xmlstarlet
    remove_gamelist_entry
    reload_es
    d_msg "$NOM_PACK a été désinstallé." "Désinstallation terminée" 8
}

# ---------------------------------------------------------------------
install() {
    local WARN=""

    # Vérifications
    if command -v batocera-vulkan >/dev/null 2>&1; then
        if ! batocera-vulkan hasVulkan 2>/dev/null | grep -qi true; then
            WARN="${WARN}\n- Vulkan ne semble pas dispo sur ce GPU : WebGPU risque de ne pas démarrer."
        fi
    fi

    # Migration d'une ancienne install (évite de retélécharger Chromium)
    if [ ! -d "$APP_DIR" ]; then
        for OLD in $OLD_DIRS; do
            if [ -d "$OLD/chromium" ]; then
                d_info "Ancienne installation trouvée :\n$OLD\n\nDéplacement vers le nouveau dossier..."
                mv "$OLD" "$APP_DIR"
                break
            fi
        done
    fi

    # Dernière version de ungoogled-chromium
    d_info "Recherche de la dernière version de Chromium..."
    RELEASE_JSON=$(curl -sL "$GH_API")
    APPIMAGE_URL=$(echo "$RELEASE_JSON" \
        | grep -oE '"browser_download_url": *"[^"]*x86_64[^"]*\.AppImage"' \
        | head -n1 | sed -E 's/.*"(https[^"]+)"/\1/')
    VERSION=$(echo "$RELEASE_JSON" | grep -oE '"tag_name": *"[^"]+"' | head -n1 | sed -E 's/.*"([^"]+)"$/\1/')
    [ -z "$APPIMAGE_URL" ] && d_fail "Impossible de trouver l'AppImage Chromium.\n(Limite de l'API GitHub ? Réessaie dans quelques minutes.)"

    if [ -f "$APP_DIR/version.txt" ] && [ "$(cat "$APP_DIR/version.txt")" = "$VERSION" ] && [ -d "$BROWSER_DIR" ]; then
        d_info "Chromium $VERSION déjà à jour."
        sleep 1
    else
        rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"
        telechargement "$APPIMAGE_URL" "$TMP_DIR/chromium.AppImage" "Chromium $VERSION"
        [ -s "$TMP_DIR/chromium.AppImage" ] || d_fail "Le téléchargement de Chromium a échoué."
        chmod +x "$TMP_DIR/chromium.AppImage"

        # Extraction une fois pour toutes : pas de FUSE, lancement plus rapide
        d_info "Extraction de Chromium...\n\nÇa peut prendre une minute."
        ( cd "$TMP_DIR" && ./chromium.AppImage --appimage-extract >/dev/null 2>&1 )
        [ -d "$TMP_DIR/squashfs-root" ] || d_fail "L'extraction de l'AppImage a échoué."

        mkdir -p "$APP_DIR"
        rm -rf "$BROWSER_DIR"
        mv "$TMP_DIR/squashfs-root" "$BROWSER_DIR"
        echo "$VERSION" > "$APP_DIR/version.txt"
        rm -rf "$TMP_DIR"
    fi

    mkdir -p "$PROFILE_DIR"

    # Libs absentes de Batocera
    # libcups.so.2 : stub sans dépendance (594 fonctions CUPS qui renvoient 0).
    # Chromium est lié à CUPS uniquement pour l'impression, inutile ici.
    d_info "Configuration du navigateur..."
    mkdir -p "$LIBS_DIR"
    base64 -d > "$LIBS_DIR/libcups.so.2.gz" <<'CUPS_STUB'
H4sICKTZ8moCA2xpYmN1cHMuc28uMgCcWwl8TNf3fxOJJARjKamtY1e0HbFryUSCxBIjCbE2M5IJ
IZkZMxNElUmIpZaMWGsdkVqLsbW11aAURVNLW0uJraqqorXUVv97Z75v5s0Rv//v/8/nc917zrvv
3nPPfs8bk7r26uYnkwniXxmhs+CFBEGFfp1cJsG1F8qzfysIIa65/sLr/xpN8e0Fubvj7wXwgQ14
0tdo5NtL33Pt5wSe9IoI3176XlnWlJXc51C+5dsXYbrYi+/5/R/fC0Lvj7bOD/wjvULw7el7RzGP
9g0F317kffxNS8r/Zz813nsdP5dV8e3F/fqy98oK//0f2CnEYb//lp8yyTnl0Jnusf24XJz+Ln31
Pq8GmD9P6j2xa+Kj544zK9uYulScF3xtbWE6nxfMXoxn7RIb12SL92YtgMF5DF6PzT5nrRlriwD/
hr4P9vqCwRdY2w/8PtbqS87akK33ngROYPP+kfnyYwyDV2BcgY1jWZ/CeiV7txZkFs3aXdamMfwU
1n5nLYe1WnjvV8l6B1hLZs8eAO6G/VJZbyN7n2CtC8NNYC0Cz8LYnh/w9Qnfr7PWiwFN2fOtQJ5m
7SvWDKy9zXWPtbOstWfPK4P2qmwcyHo73onCegcZ3Bxz1rA2USK/2Rg/Yu1fCc2nJWOuJv54nytB
BdaCGK46A98l5/yDtVEM15qfV4Kvxt5JYX0k63finU/RGzivMa89e/4n6+8TXW7AmonNU7DnbVh7
m43vs5bE6ebyZi2fwfO5HmPd8nj3S9ZWSta6jf4om5eLuf1k/9mWLrHnTVg/ToK7gr4ro+cN8Kcu
60P9vHO+F3VP8l5jPM9ka9YGbjEbt2G9g/XnJHPTGfwz6zdzm2Ctp+TZP6ztYM+7sPUGEfr3MLgc
w7dk/Z+slWfjj/DsENdRcr5F6EdincOAC9DPBH4z+uGsn8vaWsDlWNvLxnE42xtsbJKs3+c1/N0o
6gL8BP8bz3CrWN+K9au5vFh/l7WpbDyYyxnvTsa7Pdh7Ddn4J/gj8W8Ua3Nkbr9bj83py8bTWavB
xpO5P2V9fwbvk3l9Wgs2rsn6Eq5rrHVmbRdrBdjrHdaesnaZwSdF38TlwtZayPqxrHXi6zG4E56f
lJx9EuHDYQk8i7VfJGGZ/yXJ3PHQlQNg7psM8Q6QHYG7w/rtrH/MWnM2fsna55x+biusBXP/KtHL
YPbsb8neO1mryJ5HMxxPTWpL5n6AfgT3f+yZmuur6BswrzrrG2AcyX0Ym/cJ6zsw3E023sB1Be98
w9pn/FzcvwKXwWXD+iXcz0noWikZb+XxiK1n4Xxm+ETWumNPpWjzrP+A4VrhnToMPotn+3nsxfyD
PNxyW2Nth2irbLwGc49KZDAMuHD2ro6N/2BtN49jDE7jeofnm9DXRh/C+jqsXy5zx9b+WC+Mu1H2
bjvWLnI5MPgUsYt+PGZIzh7B5sax/gfWFkjw7+M8fzHcGzzHkMitEcO1BfxcsnZX9BdY+06C/5nN
v8P6hawvAa4NG7/H2i3u/yT7zmRtC+Bk7rfF3BJ/Osn4Bj8fmzuQ2w/e+YXrJp63ZeP1nL+l+Igr
DFcV4xWS5xUFb9DMZd0uyTvTJGMNawNK8TsfsffKMt5U5nJj7WPuM7mNSfi3jM25yvq8UujqyGM0
xjwnq4U5jSVz3uL6Jnm3Hs8NS6HlW8wZzPrjwN1DvwV98/8i3yvL3h+BtbQ8x+FyL4X2z/7DGhsl
4zOS8QCs856EP0oe/xkc6Pf69d4vBWckNPUQ95Pgq7PxDJ6jsbW3iXrL4POs/YicOou1DxkcI/vv
c+KrbO5D1qIk7zxDX7+Uc9QEbjdrQ9k7lVhfzPq/xLwJ68zlcmTtEx6nCD0vuV4AF1kKra3Ivuv4
2bk9Ya6mlHeqsnc2YLxE5pvvf8hjG7d/rPslnmfzPArjbng2WrJ2ItVxNmcWe/4uwVu5H+J5LNdT
yfsyNn8pg9tJcDHoM7lOMnwhj7HYexWDl+P5Um7TDK5Sigze/F/k24M8v8zaeX7vkeDLYVzjNWvc
eM0eQ6R0sDZf5r0HumKCqNMS3KTX7FENe9Rn/VDgWnMfjXEHMQcp5d0+4Etr9A//D/fAwlLONlCC
W8BaS9aaAqcnc1uWIpNl4p2H6wPe64R5BxhsZq0eazcl78Rj3teSvSeWQttIng+IsZe1eTxnZfN4
WeIJv7e8Rlax0rj4mjnHJNft79icUIyfYL6F9XV57H6NTwvDvHTAPSX7HMN4Neu/5vZGaLjI85HX
rHuLxyDMr4K+TClnaErgNNYCJfPasXacvDeEwU+572J7/8j6OWSN7TyPYn1vCe5xKXvPZrhtwA8C
rglbszvDzStlfgcJ7pvXyKOY31PFuzfra2De3lLmjmPPruG5gzwbztqD/+AnQiTj8ZLxEfTN8O4z
mW8NTvoXStY/Ani0BDdB9HvsLLzc0ovIuy7DZZF1zJJxZfZMT56LZcAXBG9n7VopdL7gOoT7lAxn
CXH5xCj/q/wmVEEeoF4tNJUL2VH1NLnlutQ/WzQscG500/plmk5VZAdZy9iDbHJBtqBKqNW/qyCf
Ua19UG5OZVXZGNuRQ6GT54UENPTPse/029gop79GNdv/QLqwJEgdXbl6Pf8p2fIgueyYIqjKuqZK
//LlFQWfVnuDE6pSD+m7rDaLHNGhZQV5x0IWwBXyL4KH+7OrhHr6uJAW/dZE5cqOlf2Dmbk19NTA
Skdbz/AXgoJU/sHtVUGCf2GdnOp+SuU3ZW3NugUxSUyRy0M71guWlznr7x8V5h/QUy3IjioEvylV
f94mVAmRTZerhHYalapiroonYbXeeNcawe8GQX4HnQGCTP9GpHLwsPy59cOqWIXsmU0sU1VdythS
jEEj/ORBwTNk2TNU1jdVO4SGUxrYrOmqelMEufwgv5Q2bDY5slrTikejjeq5/YXK8xrLqtQ1Ch2P
LlTIAhvKZBrBqqhvrWqtLJcpYiZHVE2YHB0k+Fmr2ZoqAsqarJHZacIyRUCgLEiw1vsuO1geVE9W
HKeyzrA1rRAapAgNFawsiR7it0Oo5Vf5ULR/OaGaSiO08HdWEo40m6DxD51ysEXonGz50hpOQVEm
eErZaHVfZcg6dZCrPqW46h+YUz4nZmPXXYejow7IlTnzGesUDoXcr8gv23X1dd1z/ZGri7XEQKI/
QZJxMLEdaf7N843K0DVXTiK4a0I1JPGS36XrIPflcVMsLTeR+LLmiHnSPIPHI15Daiv4+rYOkvto
Z2KnEbh7RuGOw2NTd8Fb1+tB6ie9kSe5aqSoIfVDHiT6t8HIAT7EXUIriUv83pNC7jqiLxoB3zxK
EitoXDUQ32GCL8iU1IvGouaUBd/yMckxeB2D1874HYjnjJ/gbibW9bivz5PsYUM8nY+4v1jyjOdg
ywmNK4i/ESR1oUJyn1grud9sQE2X/m1CLUu812xD7eELSa1OvMvxGPC15N1DqB0cQRw/TtY+Jam5
ibXsH1A7Ff94zZTX1/gd4mfgziM2/4J4dA01WH5vvSmJz79Jaof873fUO8W/P3FvE+8GYo72BP1T
wfcu/gJ3A4H4dV4X4bGf3+d4nbW85DmvKfA8mccWHivEXIHnlvzOJMYoMWeuJXm3tmRcR+at7fI8
rb7kmXhH4DU1XkMQ7y5ifijGyndQG/DcBzHmNUeeJ/H6XVvJfYDXqnhe1gl1NUFy5+e1LV4fF+9H
4v2M19S7447Hcy2e4/E7Na/l8fye1+/EXHYI4SO/r/G7E793JOMZr/frJHX6NIxHibmvzF2P5ndU
E/JY8Y/nhrxmy2tPPBfhdcqPUNMX/3gONwnfDMQaJf+OMA33WX4/5LXUPMk3grmE7nyST/E7B6/J
8Hr5Egme37V4bYnXyFYBz+uUPP8sRC2L12fXo/62ETVBXqfidVxea+bfF76QrPkl6p3i326Zb02Z
10q/lnyH4TU0/n1BzO94TsTrGWIOymtYvPbDa2u8Lv+DzHvX57U3no/+jHu9K0eWuWvtAmqsvP7D
7+y8nije0Xg98TcJXbcJ//g3mzuo092VPLuHbwZivewBagHSfPcJcmVeP+X3Wf7dIwA1Dp5P8Zp6
eXwDqVhKLs9zbDnw/C5bDd8GagDHvw3w+q1YV+B1Vn4nqOvnrafWQy2V39/5twKeYzdFHVe8O/P6
L6/F8G9IvMbXwc97Z+f1T173Dffz1g75d5duhF6eb/MaJq+JinX7Ewe35U3uXX2gNmhrz5bVfx0V
XKbirS1TW1w41ji4+fon74cublb/zp9n7NfXbz876EHwpkmBj9sl+VVpbFnV/6uD2x99uGffkmk5
JxsXKo+PHrlwUNQ7WfdSO67J6rxz39lPmmx/ktnzi5YrH1093TNm+qwb539oVfvt8Gu38kxRQ9eP
T9iadWZVjxlT446Ej3du7Vvc5sbpLdl1W54dMnH+H39PePvf2yXn1p5adyzjiHzbkKR1O1tOe9Ir
p9uL4bdfvtO61YrisKWpx7bHzRgXHJBQZcPOR9a/Ep5t2n85dUvM1EZpTxs+efJWi2r5W6Ytardt
9NmBwc0vhXy89epbufqOfU80CA+tVKFw0NQaH0d3f9a884JZXyRaynVo3qvgnUWPdr0d03dp89Z7
srILmpQ73OxI3BJT7WvBsuVpjTKNmoMDL50JvxAnHzKz9/i2L51Lx0wbODrXf8G59T1mqR9MDg9a
Vb5TxaW66vGXP18yMXDC32F1z0x5afPLu1fpyjd/LXhv9D/dK6WN2FZ+ScGWa8sLTl9drUx8OKj2
7LMjHl88OU1/rnCq4Sd5UejaORMfhzR5mqbtINzPaLXyWZ4+9uCFka0DZ2dtbDkjxJJT8/K1uWVk
+1OqbjmQuvfKvd2tQsqZZI1q1s2udX/fmhl/JR46MCVv6OLAQoPDVpBmP2H4IT10QnHFMYUr1BMb
lm89Rd8397t9KXcG71r59fdJbccuPdB2eu2G0R9NyWm5NWD69tNDLjRIu6v8VSg/zL+q8mj6gwpX
7u1QGr48GJDeofCby5fzh9bsd2T/sMxPwru1zPvp5fcf9PtQPz3p0NN+l/8++f25FR2W/Fhrac+d
B1Otoy+dSlk1MXnXzEGd2y9reW1c26Tc8B578gMMfS8eufx85vw/Gj//+0T3NvqE8IX3Il62Wfi4
aPOP65Ze7zzw7vom03OODPvg7OPr+VXunDwzaeLeN98Y/teF6cvGffn9udHzrYmGC3vPr60/K3Hm
2GOWmZdHDdhycMWLbZcK487G5/zWyzA7c0C7je9vjk6tcbBi3Omal+01CifpTw0e1nlcnYULB8ef
+WJi0N4ygx3jZrU4cim6x82B3cetuHps2M7wbg0G/ao067omj2j649rM3icX/L4z7tCs87EFhmUT
InMVyYf+Odi/ZrXNCw51zjnhjBmt+6DeykdV2oV+/vCzoE8X38642WVdxIvTM4d+H9uvats7WdlC
xF8Np+YkVrjYZ2W9Nc0uPEgI3XT+zbLFPz5vOumrjy+cnV7+VttFhtMxWYuu9zqb3aNM9/0nhjum
LSu/qeMAXeTUH6ZP/jJkf0jNGwHPL9mvl237+drJx0eHTtpQZmPgFP2UtuqcK2ntLdfvb2iVH3tm
qLL915fnHdmZPKBxvuLHu83OdkofOf9yj7uPe+VmZ1oTfxuyp+bntW9H1Jkx5t6ppMi4BWeygp0H
Fz+de/z2y3Nrt9Q7uk2/s0dBQG9ZQq3MvuP0e9desHQLNCX1m6a+0LpTbvNPjJoqh9bmTWwanTa4
4E1dcoUNVw/ejg5dNGyq6fa0rU2iv6vWosJtY9AdVfIzK+PL2NNVwtcdmNemzg8N/60+JGF2J51f
o4BvFMeb5m1au3p9wurkLR82mrt4U5NhPaLqb6kz+uqDb06PvRqanZP7/aQKHdrO1MQvz4mM7BLe
M2DWwG7/Kt6e/caalwFni7vuLWOf8aD+DzXbVVmQndN8/2BVdSG2U26B+e37G67cCK/7dHCbXa16
BP67PloxemJG3b/2V5+ZP2NjnYuHmjzv9N6szw/dOdokN/rf2S33jbE0qqGeKyzSbrLvWnvl5Uct
Vmd82z/6neWTm2+7dOZcQo9BMWMnZkyYvOOX7Gby7T3b7J60e94HozrUZPoTeLDLL2GrP9A/qWy9
tu1Jz8DNBn2LgpipPUf2X3jsq887yhpXz3ggK7N0d5ulBV/8NH3qlu1h8b+u2dppL4MfF816dqn5
oWV+rS6ejL95PLvJ7PFCtO346KfOOp3vN+3w9FbuX3FFI541blc5ZsEbWdEHZX5llr7Y2f5S40M9
2vTXD4reUuvY4Ir5FWrHf39v+uIdi07e2PsoILJP7sf3kkqWj85/9ji1rdBsX+TqXRdzf79z6M+g
lMq6F4qp3/2w63Bs/q6eRe3mTAx5WSHy6WenDyx9qRv8e3DIm3m12zmvLSxYWmXx/JDx9xrF/l3x
2/iAuNHnp/4UerXesDUTVJv0l8f7nbrYaUjNurXPrgtclHnYsDtr754//23a63je/j/HHZlZVvj5
p8zen/QbGK2PmXyu+9zv8mPu7zLu/LXvrCk31i1rkhXf7sjvhX/Eyy78ds586/r1wPs7pufsm7ys
QP1kx7KLA/vpx09v+/6XEybs/SL0xkTef7RnWpU9PVRf99meW/avBnnt2i06OXJleUuO6l6Xjtll
9WkXx0XXuT6l7sOsTkP6vnUwPPHKoAHX68f8s3XwKVlG34qyy5aKZxUlC16mpqviFF2W5Wkzxhb8
dOfbYOduIf/nBo3++TLv+2l3Zh+dmjPmQv3a354Kav7LgKxalcrlXcr9KWj9qfyMyA6dD73IMY0+
97LwTM9im+PNt9ouLUiM3TopP+PB5Omyau3i629f09jY+eH9i5+Exx2u16JvnnP89WG1Ov+y+Pr8
JqYNtePmHFiXvbfF/r8O1Q1vozgnq/VrK/2S2B83dU3aaUkOvxE6ssy62r2bvDieVCnqxtdT7j+7
/mzr2YG7dryTeqBx4UdHdu+zhESNrRU5v8p7j+76xV/4dYXdOHbvCLu6cyNb0szsxe9a73w5tOO0
epbV51/UfetW6pTMgluzE25a1+yzNbj4z8fbo0q+i0r/qLGmRWq/gtDDtZLkGx4pWu4Y3OiTQNuR
sLzAhgmdG/VqUOPa4X9fhn0b/3T+3qHNQxZWzZxXGPDtjs3L7m/qfKJ36tOkZkcs09Tld+1bHRPX
6o+fhy4td/PCjwsLBxzNOBbUIu/63iZTOyzo+3jKuB9Cm8SaH1b+YM6nz56ltZt75tN2c26da7z6
bESjDTMfhM7t0adTmztb8x99Oz+1Z6W18w5vOhHV/WHVxVkR1241XvT96Lu3l07MXdU58fD+qmvW
3lH4VTm5d/X5OqNWJ7zcWuOtzTX/Vie0qdmhW0RmO781ze5O22ietNyo6dujyZ4lMavlG9acGfB+
QERspd2bD8Uanpl760+1a19l8M97Vyqj9ieFL9txovsm5b2PQuyPl/hvj3s6LO542cJPcnp9GSBM
G5z3zf6Rw5abC7r3XZ+/4XDgv28vHtQr8h35J/80e+T/k21NeNGS4e81+bB43JEFk+RDJi6Jrvzs
aYim0e+XlpYfOWlOdNfORd3H7M2Jn5gRNFj1cNWIZRt6zJqW/cG0bX/Oq/po6tSao+rIprcYvPz4
ver/qR6/LYjXTAKF4kW+9ZeVdd1422ZffFhlN15p98Wfqgf8Nl/8pjfc+JJCX3yI3I2Xr/TFmwJB
z0Jf/LvV3XjjZ774SuXceMWnvvhH2FdF5i8qC3oW+OI3+Lnx1nyyPugxEnrG18K+G33xd8EHDeHD
nxVwrmW++DsVQc9yX/yZANBP6GwFeuyEnjmgR0noeQJ6jISesvVxXoK/DLkUEbnchp7IF/viH9bE
+ht88cY33XjnOl9872DMJ+u8B/qLyDq1GwK/wxffPQTnXeqLHwT5Ksi+T94C/Q5f/EDIRUXkEgO+
2bf64vdhHecWX/w/Ddx4B6HzY+iVmuhVFujXEPr3QJ/tRJ/PQ/8Va3zxEyvBTlf44ouALyJ4fj91
0T/XF5+I8zrIecdDT+TbffGTML+YzN8A/VQQf/IcfkOxyhffGPwXCP8fgj9FhD/hmK+gdgT+2wn/
f4U+qIi9vFRALoR+PeYXEbubWw10Ej+2AueVk/OmV4Fc6Hmh506i501g7/b5vvih0B8l0Z+dOK+a
nLexqIdEXt9hXyPxD72gVzbiJ/v7gw/ziD0Cbyf41eCbQP02/IaV8CcV+uMk/E8NBT1rffFT4Tfs
xG8MgJ+3E7n8gnWUxA9EQf8VRP/Xgw8lhA8jgXcQ/HbI10nkWxH7qgn9yfAbGuI3YuD/VcT/DwQ/
nUQPT0Af7EQfErG+mqzfAP7Zup7EZeibgqxfVoxTxO7kZaAPZN/q8PNGwufI8uD/El/8ZtDpIHRm
Yr6GzL8NfDHBHwT9SkJ/HTHeEb06ADtVEj2sDbz6c2Iv0Cs5kbtGwHybL74a5GUl9HSBPRYRe9wH
/+wk/nky9nUSfd4MOSqI3/gFflUgevgd9NxO9DwG8dT1oUP6va025hP/cBX2riZ+6Rr00EH04W3Q
byX0V4b+GAt88R9BjiVk/YqwdyWx9/3gv4PwfwXsyE7s6AHkoiZ+KRR6XkL0/DfYu5LE2e+gt0VE
b2dCfwSiV8GIF9bVvvhy8MM2Isc48EcgfrUc4pSC5C2H4VdLyL4PwZ9iwp/xWN9J+J8KvmkI35bB
jxURP1avKvhD1plYA/MJ32Jw3hJy3jbgp5Lw8yH8qkDWnw16nIQeG+zITuyoUR3Y7yaSX4GfAvEP
a2AvVmIv1bC+gqzfDHmRg+TPkZC7g8j9J9ynnOQ+1R30WIl8l4JvKmKPX8G/ycm+IyFfOdGfTdAH
O9GHZuC/gvC/P/hvJf6kAPsKZN8lsJdi4idrIY9Vkjz2T+iPhvDnD9EuyHkjIXcjkbse9qsmeWAq
/JiC+PN8+EkHubcOgD+UE3+4DP7HSfxPFPyVk/irQOiJnOjJj7BTgaxzD35VQ9YZBH7aCT/vwq8q
Cb4x4q+VxN+boF8g/K8I/jgIn/+FXIxELv9gfTXJH1oiLitIXA4Hn1WEz83hh20kPtogRyOR47uI
LwKJLz0xX0nm60CPmtDzN+xLRez9EeyxmNhjC/CniPBnOuJvCeGDHfwpIfx/H/xUU38LvIPgi8C3
EsK35/AnGhJPHeCDnfBhI85bQvxJMvybivi3ltBbFdHbOeCDkdjRKdijnJx3MvhvJPyfifxHTu4p
u8R8g6w/E3YhELvYgvgiED+wE35YRfKrVPDBTviwBPdKK4n7ZSAXOZFLBORuJ3JvBHqMJN71Bx9U
hA/nRX2g9oX4KxD+t8G5nMTftsS5NORcFcA3G/H/+ZC7kcg9B/taSdx/D/PlZP4pzC8i89PhZ2zE
v1VF/BVI/FVDn52ED0HYt4TEqXU4l4LoQzH0v4jo/2jsqyH79oaeawifixEfi8i+Y+C3HSS/ugL6
VcQeP0P8VRH+WyEvJ5HXOcTZYhJnP4Qf0BA/cANxR038ZxvooZXoYSbs1E7sRYY4ayX52FPwv4jI
/TzivoroYVPQryb038S+KuIfWkFeciKvMZBvCeFbVdBpJ3TOhh0JRH/6w58IxJ/8gripIHHTgDqn
kdQ5LyEvKiF5USzikYLEo1WwUyXxP6ugP0VEfxpAD5VED0+DP07Cn8fwJyXEnwSKeBLf/RGPNIT/
0eCzk/B5DfS2hPg9P7EuTegxIq8zkn2toF9D5r+NdRTEb9xE/C0i8fc0/K2KyD0edNoIna2hhxqi
h89xXiPxG4chLzWR1x/Qh2KiDxuhVzaiV4uRz8gJXo77oIrgZ0B/NER/lsFf2Yi/qgI9V9B4hPlK
Mn8/4qyRxNkM6L+D+Kve8Hsq4vessF8H8RsVwGcl4fNY0FlE6DTDjozEjhLBZw3h8xrYhYPYxVEx
XyX8TITfsxO/dwH6oyb6U1GMs0QPr4CfRYSfu4B3ELwR/r+Y+J+uYl2dnOtN5PMa4n9qY75A/G0X
8NlI+HxNrJ8Q+x2N+OIg8cWG+cVELgPBBzXhQyzOqyLntUN/ion+JIHPTpIXlYFdGEmcSoR+FhO7
2wM+2AgfEmBHTlK32Yr8zUbyt07wezbi99YjjqhJPn8GfkBD6JmIfUvIvhmgv4TM/x16LhD+z4B9
WYl9HYZfUhG/1Ap+VUX8anPEXyu5v7SA/5QT/xmNddRknUPQqyKiV0Ngd0Zid3OxvpWsvwF8Fojc
zZCjmshxD+xUTvzJM8RHBckbd0FeGiKvSdC3YrJvNvTWSPQ2D3puI3peF364hNBZCLuWEz1vjX1t
ZN+h4IOD6Ntp6KeD6KcZ9BgJPTHwbyXkvHNwLis5lw1x30rygW2gX0HonwL9tBI/3A9+w0b0dgXW
t5H134ffVhH/thv+TSB+2AH9sRP9OQ87spE4ZYaeFxE97wb9sZH15wBfTPAy2J1A7K4W+OwkfL4H
/S+h+g+5CySOROFcSnKujZCXncirtvjdmfD/KOKmisSRDyHHIoK/BnkpCX/yoYfFRA8P4R5RTO4R
auDVBH8VfCgmfPgUfsNB/EYO+GCk8hXzH5L3/oF95fQ7BfTKQfTqDcQdI9HnXPgZDbHf02KdnPCn
MvyMkdCzCnKxE7kYIfciYu8arGMn69SCXcuJXbfFfc1B/Pw28KGI8L+CaBckvlSDPQrEHhdD/0uI
/n+MdQRiX88hX4HwuRXikYPkFXrYkYbYUSbkriFy/wHznWS+EvUBNfHzcyCvIuJ/zov3U2Knj8Tf
qxD+NBZ/V0D4uQL3ERu5jxwFP52Enx2Rt9hJ3vI38igr4c9R8F9B4tpy6LON8PkW9EpD/ElfnKuY
3K+bg58Kws+9oEdN6AlD3FGQuHMG8zVkfqF4vyB+ZhDkZSXyqgg6bYROFfRKTfzGbvDZQfh8BXQ6
CZ3Vxd8REbvrIN5Pyb0pDXI3ErlXh1w0tB6C+VYy34bzaoi99IRftRO/WoB1nGSdPqDfQeg/L8Yd
cn/piO8OJWTfFbBfBcF3hN0piN39CPpLiLwSIV87yf/Pw386iP8sj7yomOB3id/7iJ78DPkWEfkO
B51qQudT0CkneWkd6IOc6MM+8XsW2VcPOlVEH3rAfh3EfmfDDwsEHyjaI5HXF/CHSuK3W4rxmvAz
EnZRRH9Hh7hQTOLCSNiLldjL79A3FaEnEfQXEXqaQn+KiZ7UQrxWkTjbA/HLRuLXAeRdCkL/PdiR
ivi3JOQ5apLnKJG32Im8Poee2ImefIS80UnuxQNRf7CSfSfAHxqJP4yDPiuJ3h7FPchB9G0K7FFD
7LE61peT9ZeD/3KiPyngj4P4mU3Q8yJij+HQWznR247gv43kLQuQ/xSR/GcL9MpB9Ko5+KYhfHsK
PqsInScgRyeRYzDOpSbzl4M/NsKfNPCnmOhnhOhXCR/24FwCkXt35GMqko/9C745Kd8gx2KSJ2wW
790k7k8Tf09C7EUGu9AQu6iJc9nIuRRYR0XO9Rj6Vkz0LUD8fQ6JF42QJ9tIneGReC6inycRF6yE
/ofi781InLoBP1BC/EAt7Gsl+05F3mIlecuvOFcROZcGfq+E+A0/+P8Solf3oW/FBH8IeZqDyOsI
8kM5sYt07CuQPDAPcnEQuVQQ6zNEr87D3yqJv/0U+xaTvPQb8FkgfG4BvikJ3xSg0074Ey/Wu4g+
zIIeOokefg65q4jcq4HPAomzWYibCpLv9YccNUSOeti7k9h7B/gZJfEzb4M/asKfTxE35cReZsH/
FBF7n4R4UULixTHIRUHkosI6VrKOHXFcTvJqf+hbCbGjcrBrK6GzPuKUnMQpI+xRSda5A/rVxD8f
AV5J8P6gX03ol8EeNcQeVfCTNrKOFfwpInq4HXpoJ3oYBv1xEnu5Bf00Enw2/JWd6Gd38Xc7JP8p
hzzESfTzTfH32GR9P/H7GtHbNpCXgviHWjiXgpyrslhPIHTWE3/vQfQzEfdKgf6uA/mnkeSfn0Lu
ViL3gZivIvMnIv8sJnnC17AjJ7EjG/hgI36pLuh0EH1OhL2rCN8Ogh47oecw5jvI/DrQTxuxuzOg
X0n08CL8g5LkFbORt5QQ/9xE/O5A4vUX4vcysv6X0Gc5sfc74u9wCP9z4cesxI/lYV8l8XvfIC4U
k7hwRPx/IoSeZ9C3EqJvqZCLnOjPNfBBTfz8V8hbbIQPXWHvDrJvdbG+R3+3g/lFZH4nzDfS3xVA
r4qJXs2BvSuIPcrF/69E5Fgi/i6a/q4V+iYQfeso1kmIf0hBXCgmcrkPP6wh9tIR+ZuS5JkbEX+L
iR72hLzURF7H4W/lJK79BP1xEv0ZhXOpybk6QO7FxB7tWMdG1vka8UhJ5u8E/SWE/snI0+wkT/sU
+mMk+iMkJWcazREmkzYrIiUl3mJK0w83S5CxurE+yC6Zqak6U3edRQrG6dJ1WrPOjYo06FO6mAza
lGSt2eJFxejTJFCiVgLpdcleYIzOZOljtKQZ9Ngx0qTTWnRROnGxrvpkQ4rOPUWCYSTGajNAQ7e0
dF3kCF3yKAKygUVn8iLVOt2oiBE6bYob1T0+Pl5nGpOWrPMuxY7aMqx96/7a9Eyd2YPi5MTpzIZM
U7LOB+mdotaazWMNJnHpdMMwbXovg0iSG+6nTycYvN9Lqx+uZmy3dDWZDCaCk57Cg0yVwJkWyTJu
8bnh3jqzWTtc182k0/kgehlEFngQhlGZRh8U0wQfOF47Rlwk06Ib55WvC/Se1AVKDxqrG8dYla7N
coNxid5X4xL5e3EegbjhRFOaRScipCvFMQ3TmZjeSrjkxkUyhTS9ijWkG0zxRm2yTsoU9zNGkc6z
iwvjev3ViV3H6ZLV8VIMp1+d2D2aka0z+T5g/xhNTBfUUVK8h5VukJ/31Zc5Vp02TieqhBvr4sWr
k11o6ez42N7qyHSDaJQu0GDM6hMT5UVE6VK1memWSENGRiY7Qpb3SYzZZ6ILVJt0qWyDFC+aIRMM
Uga5kEad3gt5RcmheG4jwzIls91vJxh8tkvUpo+SQF7ps/clMmUQ0w5tuvdhrG64wZLGvEVEpmWE
D2EWU0Q60xsPFKX1rGkxdUvPNI/wQgZThtaS4oU9xsKAOJ1Fm6b3gPHJWr13ZrxFa0kzW9KSIYOE
Ecx1pURq9cm6dB+My6NJMVFs2eQRUozXQSalcJYlmUWXm2TWpuqSxpj1RonZJ5ktJuZvdckZRl8E
6yQIY5YX0Hvmj7BYjMyITIyDaoPJ4ka4iWT/puj0jKdcrzg6Sse9b7+4GIBp5mTRgXPY7Zw9jznv
XlmC+830Md5JXCvShjNKpVJzPWD8zMRLCb3iuZmxVdLG6zwotU6f4pnOYLe6AWDregKJiLJoxfO5
IIPRA0DNONTPmKIVx245pBmNrnChNXGDAsQ3SzCM4uruwuhTxKDEwP5sapQuTY+3Odh1nNGlLQBd
MRTjGOk8MXBEdvGg4vlco5HpUvIIXYTZnDZcz8yRqYTZi3YLLDHNMoITVxre5YVENA9WJkOWF8Ho
6cJVWwKzM6WZRzAGe/hY2kMxNEqexeiNmZb4dIPFB9tbl5KmTcgy6nywfTItbDLdWs0jjEvUEuSr
CARgCcp3fZdUvfxwsaKbyZARo1a/iglzobjO8riZyShwn4qtKqYYIkwmiKGbjaO15hHu7IEBLv/E
iE6JsHA7ZJhY7l04qrd2lC5Cn9KbmUu664nbcWLgIdmlcl72jx3uYS3zU57jjx3u4m0sC3rgETAJ
2mHpUpAxh70HHo0dLnKZ4VzPBVfel5LiyrYkY9dDkQrgeXAbrjNB54H0gTLS9KLy6VMMY81c/zxP
mDUwXxOvzRim9SK5SFkCpuOuyOJKOj2P4kt/hMTVC7givwQ0ZOotEjDTZNJJEQj7XphlPR6A27QU
Mpklb7rUPEU3jmDMLH/1osgM+riXVroiTwukQJgP1EoKjZO8xjzBGC8Up8swjNFJYbPFYJIgXHmb
B+rHCGLB0C2DLtrkUZEjtMyfp7s8KcG5XaSIZK43SsdzZe7IJcg4HResC+MOfVyBehiGSTCvQO6T
sm2YslsSDP0SurUHhiXt/P34TCNfVeemyZXY+CzrjkEeteWpzisAm5SanpZsMftgY/SpBsH3nuFZ
1YURoag0kzuhAuCyV4w93HKNx4pqE2XgIY0Hv2Stxy6iDO7gMTpTJDDKENPHF5ZC0vuO+VVMmIgy
ZXltr6s+M8N9G/FcfzykuyBDBktLWRzBfI7r2qebZ+xRfBfgSo9EiCk5l5MPzBgrhXul6XVS2EuF
61YgArGZGcN03oU8/BSBbl4S+D3NZ1dceTxgpi9RHJYS5boRiYBHWG5grPSs8WwjL2BhWbZJCqbp
pZAh0+IBE3Tp6R4AdxQR9NoN5yuXCzJvHxwnK8sH46v07njretuQnJkhejGgfVAsgvmotogweyCm
1F5AqltcnOksAdF5QR+zcV1zvcR7wTBBcguWjl2xo4vEE/riXbHyVbQrjFG015lLsa/QY7bwbEd0
S+LFXEIg91qe40DNXBlNumfPV6MbQ3q4hrFnSX6IFOnBfd8TA597GCYZtxJItcD7kGu4zuTZj/lx
IxOSh0B3MBRXju4dEelx4zwF8QGQVIsVASnDOOxJbkSE1+JdEL8AiQDPWt1jM+5iPpB0J+Q+Hjm9
gpUwSYp25ZMuLM+R3OeUXiLcT0yjpGoby+59qVnxmcNG8quIF5MgRkqfPMqFQCVF5wuF+YJkLiTO
3Am0ho/ENcTKg+ho3bDHrXnBmD5CaZf/MKHUaz7QbCyqgEe27ljv0Ts3KOEqblq+FhzvitHe+OJm
MIbM+NMYnyNZlsKuHyKOMD/eY/RR3kUsXgcT72Nx8a7sWRqd+MWMB0bvDpIrzysYzyq+hEIvfAgt
XVfYA57lSMcRw0VfGZ+WokN64xt2JQ88AUOC45UJ0RYI2lW+IHhvCHBdQV/x4m6sFJOgyzBCyVxD
UctEwM0Wlim1CpMkTHyQYEAiJcG45rlhkRW+fHARiPO79MtVFEhO1hktSK649FAp8HL4f9q7n9hm
0oOO47O7bjGt6bptoC6bbt3Wbd02G2bfum1oQ+vtm7ZZarRm49IcIq3ffZ1dR/h9MyTO9n0hQj7k
kEMOPuSQQw4+5JBDDpYIECBII5FDDjkMJUCAAAMECBDAQIoiFPHyfWyP//y26gWJQ5mR3nzm+cbO
ODP2+N/4TVCWXnr4uDffuQn0Rt3XB2R8ZyA4j3MLy/1TfO2XVgZ+8tfvPVio9H94++nZ4KnbDzgG
xrn5h29Wy/0h35t/2B+aHU15cfD0nZc6g2H7FZDeKyKd3Vl7yH3iA55MmbsVGb8xHL718lQ7fNU8
CAjO3nk1uj1nnqDcZaEL8/3x1xfmK6Xl7jhYe+ZR2r2loRdQOrm/QodWZnfQvbV1k/P4befvj19a
mmdvu1Di+V/7fli+bZ74PnIWlu71Nv7wNwtLK90VOdAH1lnnxaLPZ4YGr93pDttPvPovGnVPFgy6
JxvYdbSH7buc9ktLZo117iraw/ZdVm+uc3szQ3Mj7foSV+K3zOucwZgtzIPg3rD/8lO3DG3BzkMh
rkv9FwN6ubcxzcMLnjMM/5h+uTOYCgsPemeSX7Oz4oON3HmQEsyZ3zsYTHNF7j6EGigPB8bfnJ93
XqosvNULAzeP3qh3sYLX07rDzkPS3uDBPR5r9r9rXp6bHxys9FYld8RDlzMY9xb0CzyyGfhlO2c0
93ftmYFX+tpDngeuPPzF+e43gyc73bF570Kv4j839blAHh93dyYMBrZL8FjAzJunF52ZYMfQfX7R
nl3ppFeDS2dm7vTmgvuMzvj+wG2zNwpO3L4zHtpA5rm4XvaZeW70wZoNBneGRsE+aOZtV9qZoWuj
3HcHL7Z27rv7G2hm6No2Mz/8reFr0MzQNYiRuRYvdlfRTHmFZ0Xf6WzW9tVj4KIVlu7d7/wMLn7n
6jLw3f4Ntj13pz/be+C74Jh98lcXF9lhPhweLXeHdxcrle5dlYbgJO1X/juz3cf4w6PgdK/cr5pr
dfsCdstK9ZU3vmpewu2MX+Xh8PzgfHDW9pZeGbgU/RCcpLslF4OFDy2oM3hjePTW0LDzc6rMv77S
W8sks4fiVro88KsFafBEzuPeed8W2j+689JH97o9X2q/VGR6e7+12N5zmVFnH96bG/qhndR9cZix
eU2ifxnMqLP3NoOBpw7BsPdN82x46AebYF4Bk7i0PFzM/rt/XWnvpgevHO1gnk525oOrBbPfWFpc
cQr33uwOB1Zl95led1auIe1nffPd+8rOuHcNae8+2+vy5VJvPHgl6e1O+/Mry3e5I+yFgcW0V03/
Agb7UkbdmyZz5rXEDsEOKhj1b01vW4mvOP3lvOL0tkD7IRG294Bd249Hu/M8n2FuZmh9z+j6numv
45nhdTwztI5n+ut45m3reEbWcfCOVWe2t7pnZHXP6OqeGVjdM7q6Z2SJAzfH/uit7nBwW8wMbYvB
/R9DTjM06K1dc2MqLAbrpv1w7J7clN4W2zeozi4zmAk2SHvAFjFvbrQfSZqZzpYYmL3TmQ+eFzL4
2oOFauBLb5hnqkvmPeZu4fFHd+5n7+YGZr/2sPeN7m9nRgM3Z/OGSvcGHMzfLS8u3J/vjXgIufig
+6R1qPGU/d6DIJkn/PNy1uD6G4wHfwh7g7f9lKXeSw4MX364XL1XqZj3R4L10M7LnSWZ+f5rHANv
5QzOBwsPxi/nzRvey50FBLH98zoPr6lm1L0DXg7G/QtlfiO52Cb1T2BePrgTzHQ2inkPp3u7745m
uhczmM8tsHmWg/LthVLnpDOd1/bMG1IPzUr9zpudt77NWToX17zbtNB51y14B4mT5ObfvHf/8WAx
r0INDr/9jcFh+/yVhdfN08zx5cXxO1Y4hVM4hVM4hVM4hVM4hVM4/VBM//Hs8//1ovt7bzz74bVw
HI7DcTgOx+E4HIfjcByOw3E4DsfhOByH43AcjsNxOA7H4Tgch+NwHI7DcTgOx+E4HIfjcByOw3E4
/mEYhweGhVM4hVM4hVM4hVM4hdMP5fTUc898aft9lvXq0wy8J08OmI/jCSbRRxuvMYvR91tWHkex
iDY6OIU1nMU6VrCBNWziJrq4ix4eoo8etvACrd9/8uQG4xgbYfmYRBszmMVpzOMcFtH8PXYH17CG
W1jHPWygi008RRcv0cNb9DH+4ywfU2h998mTCYxjDpNYRBurmMV1zOM2FrGJDh5hDc+wjlfYQPOH
5Zo4gi6m0cNJ9DGPLSyZP0D3B0+ePMI4mr+blMQG2riPWTzGPJ5jEVvoYOQDLB8TWMcxbGAWm1hA
F8vo4Sr6WMcW7qB1yvbHOJ5gEn208RqzGE2wfBzFItro4BTWcBbrWMEG1rCJm+jiLnp4iD562MIL
tP6Q7Y9xjH2Q5WMSbcxgFqcxj3NYRAcdXMMabmEd97CBLjbxFF28RA9v0cf4T7J8TKH1R2x/jGMO
k1hEG6uYxXXM4zYWsYkOHmENz7COV9hA6zmWjyPoYho9nEQf89jCElp/zPbHOG5gEhto4z5m8Rjz
eI5FbKGDkVGWjwms4xg2MItNLKCLZfRwFX2sYwt30Dpj+2McTzCJPtp4jVmMfojl4ygW0UYHp7CG
s1jHCjawhk3cRBd30cND9NHDFl6g9Sdsf4xj7HmWj0m0MYNZnMY8zmERHXRwDWu4hXXcwwa62MRT
dPESPbxFH+MfZvmYQutP2f4YxxwmsYg2VjGL65jHbSxiEx08whqeYR2vsIFWkuXjCLqYRg8n0cc8
trCE1p+x/TGOG5jEBtq4j1k8xjyeYxFb6GDkIywfE1jHMWxgFptYQBfL6OEq+ljHFu6gdc72xzie
YBJ9tPEasxj9KMvHUSyijQ5OYQ1nsY7m7/Q1sIZN3EQXd9HDQ/TRwxZeoPXnbH+MY+xjLB+TaGMG
sziNeZzDIjro4BrWcAvraP5uXgNdbOIpuniJHt6ij/EUy8cUWn/B9sc45jCJRbSxillcxzxuYxGb
6OAR1vAM63iFDbQ+zvJxBF1Mo4eT6GMeW1hC6y/Z/hjHDUxiA23cxyweYx7PsYgtdDDyCZaPCazj
GDYwi00soItl9HAVfaxjC3fQ8tn+GMcTTKKPNl5jFqOfZPk4ikW00cEprOEs1rGCDaxhEzfRxV30
8BB99LCFF2j9Fdsf4xhLs3xMoo0ZzOI05nEOi+igg2tYwy2s4x420MUmnqKLl+jhLfoY/xTLxxRa
f832xzjmMIlFtLGKWVzHPG5jEZvo4BHW8AzreIUNtD7N8nEEXUyjh5PoYx5bWELrb9j+GMcNTGID
bdzHLB5jHs+xiC10MPIZlo8JrOMYNjCLTSygi2X0cBV9rGMLd8wfHL9g+2McTzCJPtp4jVmMjrF8
HMUi2ujgFNZwFutYwQbWsImb6OIueniIPnrYwgu0/pbtj3GMvcDyMYk2ZjCL05jHOSyigw6uYQ23
sI572EAXm3iKLl6ih7foY3yc5WMKrb9j+2Mcc5jEItpYxSyuYx63sYhNdPAIa3iGdbzCBlo/xfJx
BF1Mo4eT6GMeW1hC6+/Z/hjHDUxiA23cxyweYx7PsYgtdDBis3xMYB3HsIFZbGIBXSyjh6voYx1b
uIPWJdsf43iCSfTRxmvMYvRFlo+jWEQbHZzCGs5iHSvYwBo2cRNd3EUPD9FHD1t4gdY/sP0xjrE7
LB+TaGMGsziNeZzDIjro4BrWcAvruIcNdLGJp+jiJXp4iz7GP8vyMYXWP7L9MY45TGIRbaxiFtcx
j9tYxCY6eIQ1PMM6XmEDrQzLxxF0MY0eTqKPeWxhCa1/YvtjHDcwiQ20cR+zeIx5PMcittDByOdY
PiawjmPYwCw2sYAultHDVfSxji3cQeuK7Y9xPMEk+mjjNWYx+nmWj6NYRBsdnMIazmIdK9jAGjZx
E13cRQ8P0UcPW3iB1j+z/TGOsS+wfEyijRnM4jTmcQ6L6KCDa1jDLazjHjbQxSaeoouX6OEt+hif
YPmYQutf2P4YxxwmsYg2VjGL65jHbSxiEx08whqeYR2vsIHWT7N8HEEX0+jhJPqYxxaW0PpXtj/G
cQOT2EAb9zGLx5jHcyxiCx2MfJHlYwLrOIYNzGITC+hiGT1cRR/r2MId84cXW2x/jOMJJtFHG68x
i9EvsXwcxSLa6OAU1nAW61jBBtawiZvo4i56eIg+etjCC7T+je2PcYxNsnxMoo0ZzOI05nEOi+ig
g2tYwy2s4x420MUmnqKLl+jhLfoY/xmWjym0/p3tj3HMYRKLaGMVs7iOedzGIjbRwSOs4RnW8Qob
aH2Z5eMIuphGDyfRxzy2sPRl8+Yj2x/juIFJbKCN+5jFY8zjORaxhQ5GvsLyMYF1HMMGZrGJBXSx
jB6uoo91bOEOWtdsf4zjCSbRRxuvMYvRLMvHUSyijQ5OYQ1nsY4VbGANm7iJLu6ih4foo4ctvEDr
e2x/jGPspc7rUyPB61S//Kr11KP4U8/FfiRaf4rT0MxT1uzvPnnS+1um/DN3Y5PSpvg3IW2Wfxlp
FXN+aTX+jUkzfzo6Lc38OeaUtEP+JaV55nJLu+BfQtqN+d2lxczvLS1Ji0nL0KLSpmkRaXM0S5pD
uz0cbmu0G2lbtGtpe7SWNJd2Je2UdintknYh7ZbmS4s/zdNUaSnambQJ2qm0HM2TVqSdSKvSjqWt
046kbdNcaU3aobQj2oG0M9q+tCtaU5r1DOtV2ghtV1qatiNtktaQlqdtSyvRtqQ9om1K26DVpTVo
G9L2aevSjmlr0s5pNWkt2qq0SITLIy1Bq0oboznSsrSKtAKtLK1MK0lbpRWl1Wlz0nZos9IOaAVp
J7S8NJ+Wk3ZNm5YWfQf7MWmjtKw0mzYpbYo2IW2WlpFWodnSarQxaZu0tLRdWkraIS0pzaONSrug
JaTd0Eakxd6J0pK0mLQMLSptmhaRNvdOcyFl/0e7/R3Z/9FupG3RrqXt0VrSXNqVtFPapbRL2oW0
W5ovLc7gXFqKwZm0CQan0nIMPGlFBifSqgyOpa0zOJK2zcCV1mRwKO2IwYG0Mwb70q4YNKVZUdar
tBHarrQ0bUfaJK0hLU/bllaibUl7RNuUtkGrS2vQNqTt09alHdPWpJ3TatJatFVpkR/l8khL0KrS
xmiOtCytIq1AK0sr00rSVmlFaXXanLQd2qy0A1pB2gktL82n5aRd06alRd/FfkzaKC0rzaZNSpui
TUibpWWkVWi2tBptTNomLS1tl5aSdkhLSvNoo9IuaAlpN7QRabF3o7QkLSYtQ4tKm6ZFpM3RLGkO
7fa3Zf9Hu5G2RbuWtkdrSXNpV9JOaZfSLmkX0m5pvrR4jNuNtBTtTNoE7VRajuZJK9JOpFVpx9LW
aUfStmmutCbtUNoR7UDaGW1f2hWtKc36MdartBHarrQ0bUfaJK0hLU/bllaibUl7RNuUtkGrS2vQ
NqTt09alHdPWpJ3TatJatFVpkfdweaQlaFVpYzRHWpZWkVaglaWVaSVpq7SitDptTtoObVbaAa0g
7YSWl+bTctKuadPSos+yH5M2SstKs2mT0qZoE9JmaRlpFZotrUYbk7ZJS0vbpaWkHdKS0jzaqLQL
WkLaDW1EWowvcWlJvsSkZfgSlTbNl4i0OfNFmsOX29+S/R9fbqRt8eVa2h5fWtJcvlxJO+XLpbRL
vlxIu+WLLy3+Xm430lK0M2kTtFNpOZonrUg7kValHUtbpx1J26a50pq0Q2lHtANpZ7R9aVe0pjTr
faxXaSO0XWlp2o60SVpDWp62La1E25L2iLYpbYNWl9agbUjbp61LO6atSTun1aS1aKvSIu/n8khL
0KrSxsyxWNKytIq0Aq0srUwrSVs1x3hJq9PmpO3QZqUd0ArSTsyxY9J8Wk7aNW1aWnSE/Zi0UXNM
mDSbNiltijYhbZaWkVYxx5pJq9HGpG3S0tJ2aSlph+YYNmkebVTaBS0h7YY2Ii1mjk2TlqTFpGVo
UWnTtIi0OXPMmzSHdnsg+z/ajbQt2rW0PXMsnTSXdiXtlHYp7ZJ2Ie2W5kuL/wS3G2kp2pm0Cdqp
tJw59k5akXYirUo7lrZOO5K2bY7pk9akHUo7oh1IO6PtS7syxwpKsz7AepU2QtuVlqbtSJs0xwBK
y9O2pZVoW9Ie0TalbZhjC6U1aBvS9mnr0o5pa9LOzTGL0lq0VWmRBJdHWoJWlTZmjkWUlqVVpBVo
ZWllWknaqjnGUVqdNidthzYr7YBWkHZijp2U5tNy0q5p09KiH2Q/Jm3UHBMpzaZNSpuiTUibpWWk
VcyxltJqtDFpm7S0tF1aStqhOYZTmkcblXZBS0i7oY1Ii5ljM6UlaTFpGVpU2jQtIm3OHPMpzaHd
/qbs/2g30rZo19L2zLGk0lzalbRT2qW0S9qFtFuaLy3+HLcbaSnambQJ2qm0nDn2VFqRdiKtSjuW
tk47krZtjmmV1qQdSjuiHUg7o+1LuzLHykozb/LtSRuh7UpL03akTZpjYKXladvSSrQtaY9om9I2
zLG10hq0DWn7tHVpx7Q1aefmmF1pLdqqtMiHuDzSErSqtDFzLK60LK0irUArSyvTStJWzTG+0uq0
OWk7tFlpB7SCtBNz7LA0n5aTdk2blhZ9nv2YtFFzTLA0mzYpbYo2IW2WlpFWMccaS6vRxqRt0tLS
dmkpaYfmGGZpHm1U2gUtIe2GNiItZo5NlpakxaRlaFFp07SItDlzzLM0h3b7G7L/o91I26JdS9sz
x1JLc2lX0k5pl9IuaRfSbmm+tHiS2420FO1M2gTtVFrOHHstrUg7kValHUtbpx1J2zbHdEtr0g6l
HdEOpJ3R9qVdmWPFpVkfYb1KG6HtSkvTdqRNmmPApeVp29JKtC1pj2ib0jbMseXSGrQNafu0dWnH
tDVp5+aYdWkt2qq0yEe5PNIStKq0MXMsurQsrSKtQCtLK9NK0lbNMe7S6rQ5aTu0WWkHtIK0E3Ps
vDSflpN2TZuWFv0Y+zFpo+aYeGk2bVLaFG1C2iwtI61ijrWXVqONSdukpaXt0lLSDs0x/NI82qi0
C1pC2g1tRFrMHJsvLUmLScvQotKmaRFpc+aYf2kO7fbXZf9Hu5G2RbuWtmc+SyDNpV1JO6VdSruk
XUi7pfnS4h/ndiMtRTuTNkE7lZYznz2QVqSdSKvSjqWt046kbZvPNEhr0g6lHdEOpJ3R9qVdmc9K
SLM+wXqVNkLblZam7UibNJ+BkJanbUsr0bakPaJtStswn62Q1qBtSNunrUs7pq1JOzef2ZDWoq1K
i3ySyyMtQatKGzOfxZCWpVWkFWhlaWVaSdqq+YyHtDptTtoObVbaAa0g7cR8dkSaT8tJu6ZNS4um
2Y9JGzWfCZFm0yalTdEmpM3SMtIq5rMm0mq0MWmbtLS0XVpK2qH5DIs0jzYq7YKWkHZDG5EWM59N
kZakxaRlaFFp07SItDnzmRdpDu12X/Z/tBtpW7RraXvmszTSXNqVtFPapbRL2oW0W5ovLf5pbjfS
UrQzaRO0U2k589kbaUXaibQq7VjaOu1I2rb5TI+0Ju1Q2hHtQNoZbV/alfmskDTrM6xXaSO0XWlp
2o60SfMZIGl52ra0Em1L2iPaprQN89kiaQ3ahrR92rq0Y9qatHPzmSVpLdqqtMgYl0daglaVNmY+
iyQtS6tIK9DK0sq0krRV8xknaXXanLQd2qy0A1pB2on57JQ0n5aTdk2blhZ9gf2YtFHzmShpNm1S
2hRtQtosLSOtYj5rJa1GG5O2SUtL26WlpB2az3BJ82ij0i5oCWk3tBFpMfPZLGlJWkxahhaVNk2L
SJszn/mS5tBuf63fwimcwimcwimcwimcwimcwimcwun/5/SeruVUx0h33Hq64/f++8li+/vdDy6/
o/v95msd39kdX36y47u645Xuz3t3d5z4P/p9vnH37heT6W+9vvKwupJ88bPjnx23X/j8Snt451fv
ZMbtzPiLn+p+w7LGl8vL1aXqvdet8YeL1fnxNx+ujDtLi878UvXxQHp9ZaFSemGhZLVH5XvLZWu8
9Pjh8uMHHatL1nh1/lHVGp8vv/bG0r0H86+VS0v9UftU9x4s3LfG7y8+eDD/sPq//j3NejXP6bub
ydp9etiknD4q4+fl/MdPD5uS00dk/LnudeFpub4EPnrv8PUlKj/H/Pco//nkyWJw/uD6FWiO1f1+
5w+mL3XXwdNy/Qs8/kL/+vnUwPmD6+Fdq/1R5N75g+tz4IqsgKdk+d/stuD6b9WH/cDHh08fl/P/
fPf8wfItd1jzf1j+oPX/mpy/8d1ha+M/ePsvdC/7M92x/eHOb2g/29Gzhm/fUfk9lrrLt/WKGe+c
/wXr+6+/QZ/5PtfrF7rn/xXrB6///wF0/Xfy6BMBAA==
CUPS_STUB
    gunzip -f "$LIBS_DIR/libcups.so.2.gz"
    [ "$(md5sum "$LIBS_DIR/libcups.so.2" | cut -d' ' -f1)" = "c1fb903802b4d1f4619b841e61acf42e" ] || d_fail "Le stub libcups est corrompu."

    CHROME_BIN=$(find "$BROWSER_DIR" -type f -name chrome -perm -u+x | head -n1)
    [ -n "$CHROME_BIN" ] || d_fail "Binaire chrome introuvable dans :\n$BROWSER_DIR"

    # L'AppRun d'origine écrase LD_LIBRARY_PATH : on lance chrome directement
    LIB_PATH="$LIBS_DIR:$BROWSER_DIR/usr/lib"
    MISSING=$(LD_LIBRARY_PATH="$LIB_PATH" ldd "$CHROME_BIN" 2>/dev/null | grep "not found" | awk '{print $1}' | tr '\n' ' ')
    [ -n "$MISSING" ] && WARN="${WARN}\n- Libs manquantes : $MISSING"

    # Clavier virtuel manette (extension Chromium chargée au lancement)
    d_info "Installation du clavier virtuel manette..."
    mkdir -p "$APP_DIR/osk"
    for F in $OSK_FILES; do
        curl -sL --fail -o "$APP_DIR/osk/$F" "$OSK_URL/$F" || WARN="${WARN}\n- Clavier virtuel : $F non téléchargé."
    done

    # Lanceur : séparé du port pour pouvoir le mettre à jour
    cat > "$APP_DIR/launch.sh" <<EOF
#!/bin/bash
# Lanceur NFSU2 Revived — généré par nfsu2.sh (Foclabroc Toolbox)
LOG=$LOG_FILE
export DISPLAY="\${DISPLAY:-:0.0}"
export HOME=/userdata/system
export LD_LIBRARY_PATH="$LIB_PATH"
export CHROME_WRAPPER="$APP_DIR/launch.sh"

# Mapping manette de Batocera transmis au clavier virtuel (manettes non standard)
SDLMAP=\$(printf '%s' "\$SDL_GAMECONTROLLERCONFIG" | head -n1 | sed 's/\\\\/\\\\\\\\/g; s/"/\\\\"/g')
printf 'window.__NFSU2_SDLMAP = "%s";\n' "\$SDLMAP" > "$APP_DIR/osk/padmap.js"

# Flags ajoutables sans toucher au script : $APP_DIR/extra_flags.txt
EXTRA=""
[ -f "$APP_DIR/extra_flags.txt" ] && EXTRA=\$(grep -v '^#' "$APP_DIR/extra_flags.txt" | tr '\n' ' ')

"$CHROME_BIN" \\
    --no-sandbox \\
    --user-data-dir="$PROFILE_DIR" \\
    --kiosk --start-fullscreen --app="$GAME_URL" \\
    --enable-unsafe-webgpu \\
    --enable-features=Vulkan \\
    --ignore-gpu-blocklist \\
    --autoplay-policy=no-user-gesture-required \\
    --password-store=basic \\
    --no-first-run --no-default-browser-check \\
    --noerrdialogs --disable-infobars \\
    --hide-crash-restore-bubble --disable-session-crashed-bubble \\
    --load-extension="$APP_DIR/osk" \\
    --disable-features=Translate,DisableLoadExtensionCommandLineSwitch \\
    --disable-print-preview \\
    \$EXTRA > "\$LOG" 2>&1
EOF
    chmod +x "$APP_DIR/launch.sh"

    # Port visible dans EmulationStation
    mkdir -p /userdata/roms/ports
    cat > "$PORT_SH" <<EOF
#!/bin/bash
exec "$APP_DIR/launch.sh"
EOF
    chmod +x "$PORT_SH"

    # evmapy : Hotkey + Start = quitter, stick droit = souris, R3 = clic gauche
    cat > "$PORT_KEYS" <<EOF
{
    "actions_player1": [
        {
            "trigger": ["hotkey", "start"],
            "type": "exec",
            "target": "pkill -f $PROFILE_DIR"
        },
        {
            "trigger": "joystick2",
            "type": "mouse"
        },
        {
            "trigger": "r3",
            "type": "key",
            "target": "BTN_LEFT"
        }
    ]
}
EOF

    d_info "Ajout des médias et de l'entrée gamelist..."
    add_gamelist_entry

    local FIN="Installation terminée !\n\nJeu dispo dans : PORTS > $PORT_NAME\nQuitter : Hotkey + Start (ou Select + Start)\nSouris : stick droit, clic : R3\nClavier virtuel : L3 (ou sélectionner un champ)\nLogs : $LOG_FILE"
    [ -n "$GAMELIST_DEFERRED" ] && FIN="${FIN}\n\nLa fiche du jeu (jaquette, vidéo, description) sera ajoutée dans quelques secondes, une fois la toolbox fermée."
    if [ -n "$WARN" ]; then
        d_msg "$FIN\n\nAttention :$WARN" "Installation terminée" 19
    else
        d_msg "$FIN" "Installation terminée" 15
    fi
}

# ---------------------------------------------------------------------
# Lancement
if [ "$(uname -m)" != "x86_64" ]; then
    d_msg "Ce pack ne fonctionne que sur Batocera PC x86_64\n(WebGPU nécessite un GPU Vulkan desktop)." "Architecture $(uname -m)" 9
    clear; exit 1
fi

if [ "$1" = "uninstall" ]; then
    uninstall
    clear; exit 0
fi

if is_installed; then
    ETAT="Installé (Chromium $(cat "$APP_DIR/version.txt" 2>/dev/null))"
    LABEL_INSTALL="Mettre à jour / réinstaller"
else
    ETAT="Non installé"
    LABEL_INSTALL="Installer"
fi

CHOIX=$(dialog --backtitle "$DIALOG_BACKTITLE" --title "$NOM_PACK" --menu \
"\nNeed for Speed Underground 2 en version navigateur (nfsu2.xyz) dans les Ports.\nConnexion Internet obligatoire, GPU Vulkan recommandé.\n\nÉtat : $ETAT\n " 17 70 3 \
    1 "$LABEL_INSTALL" \
    2 "Désinstaller" \
    3 "Retour" \
    2>&1 >/dev/tty)

case $CHOIX in
    1) install ;;
    2) if is_installed; then uninstall; else d_msg "$NOM_PACK n'est pas installé." "Désinstallation" 7; fi ;;
esac

clear
exit 0
