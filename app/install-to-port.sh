#!/bin/bash

# Get the machine hardware name
architecture=$(uname -m)

# Check if the architecture is x86_64 (AMD/Intel)
if [ "$architecture" != "x86_64" ]; then
    echo "This script only runs on AMD or Intel (x86_64) CPUs, not on $architecture."
    exit 1
fi

# Check if /userdata/system/pro does not exist and create it if necessary
if [ ! -d "/userdata/system/pro" ]; then
    mkdir -p /userdata/system/pro
fi


echo "Installing Foclabroc-toolbox to port folder..."
sleep 3
# Add Foclabroc-tool.sh to "ports"
curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.sh -o /userdata/roms/ports/foclabroc-tools.sh

# Add Foclabroc-tool.keys to "ports"
curl -L  https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.sh.keys -o /userdata/roms/ports/foclabroc-tools.sh.keys

# Set execute permissions for the downloaded scripts
chmod +x /userdata/roms/ports/foclabroc-tools.sh

# Refresh the Ports menu
echo "Refreshing Ports menu..."
curl http://127.0.0.1:1234/reloadgames

# Add an entry to gamelist.xml#################################xmledit#########################################################
ports_dir="/userdata/roms/ports"
mkdir -p "$ports_dir"
echo "Adding YouTube TV entry to gamelist.xml..."
gamelist_file="$ports_dir/gamelist.xml"
screenshot_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foctool-screenshot.jpg"
screenshot_path="$ports_dir/images/foctool-screenshot.jpg"
logo_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foctool-wheel.png"
logo_path="$ports_dir/images/foctool-wheel.png"
box_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foctool-box.png"
box_path="$ports_dir/images/foctool-box.png"

# Ensure the logo directory exists and download the logo
mkdir -p "$(dirname "$logo_path")"
curl -L -o "$logo_path" "$logo_url"
mkdir -p "$(dirname "$screenshot_path")"
curl -L -o "$screenshot_path" "$screenshot_url"
mkdir -p "$(dirname "$box_path")"
curl -L -o "$box_path" "$box_url"

# Ensure the gamelist.xml exists
if [ ! -f "$gamelist_file" ]; then
    echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$gamelist_file"
fi

curl http://127.0.0.1:1234/reloadgames

# Installation de xmlstarlet si absent.
XMLSTARLET_DIR="/userdata/system/pro/extra"
XMLSTARLET_BIN="$XMLSTARLET_DIR/xmlstarlet"
XMLSTARLET_URL="https://github.com/foclabroc/toolbox/raw/refs/heads/main/app/xmlstarlet"
XMLSTARLET_SYMLINK="/usr/bin/xmlstarlet"
CUSTOM_SH="/userdata/system/custom.sh"

if [ -f "$XMLSTARLET_BIN" ]; then
    echo -e "\e[1;34mXMLStarlet est déjà installé, passage à la suite...\e[1;37m"
else
    echo -e "\e[1;34mInstallation de XMLStarlet (pour l'édition du gamelist)...\e[1;37m"
    mkdir -p "$XMLSTARLET_DIR"

    echo "Téléchargement de XMLStarlet..."
    curl -# -L "$XMLSTARLET_URL" -o "$XMLSTARLET_BIN"

    echo "Rendre XMLStarlet exécutable..."
    chmod +x "$XMLSTARLET_BIN"

    echo "Création du lien symbolique dans /usr/bin/xmlstarlet pour un usage immédiat..."
    ln -sf "$XMLSTARLET_BIN" "$XMLSTARLET_SYMLINK"
    
    # Assure-toi que le fichier custom.sh existe
    if [ ! -f "$CUSTOM_SH" ]; then
        echo "#!/bin/bash" > "$CUSTOM_SH"
        chmod +x "$CUSTOM_SH"
    fi

    # Ajoute la création du lien symbolique au démarrage (si non déjà présent)
    if ! grep -q "ln -sf $XMLSTARLET_BIN $XMLSTARLET_SYMLINK" "$CUSTOM_SH"; then
        echo "ln -sf $XMLSTARLET_BIN $XMLSTARLET_SYMLINK" >> "$CUSTOM_SH"
    fi
fi

xmlstarlet ed -L \
    -s "/gameList" -t elem -n "game" -v "" \
    -s "/gameList/game[last()]" -t elem -n "path" -v "./foclabroc-tools.sh" \
    -s "/gameList/game[last()]" -t elem -n "name" -v "Foclabroc Toolbox" \
    -s "/gameList/game[last()]" -t elem -n "desc" -v "Boite à outils de Foclabroc permettant l'installation facile de divers pack et outils pour Batocera Linux " \
    -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc" \
    -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc" \
    -s "/gameList/game[last()]" -t elem -n "genre" -v "Toolbox" \
    -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
    -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
    -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
    -s "/gameList/game[last()]" -t elem -n "image" -v "./images/foctool-screenshot.jpg" \
    -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/foctool-wheel.png" \
    -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/foctool-box.png" \
    "$gamelist_file"
# Add an entry to gamelist.xml#################################xmledit#########################################################

killall -9 emulationstation

sleep 1


echo -e "\e[1;32mFoclabroc-Toolbox Successfully Installed in Ports folder.\e[1;37m"
sleep 3
