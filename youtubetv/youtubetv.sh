#!/bin/bash

# Validate app_url
app_url=https://github.com/foclabroc/toolbox/raw/refs/heads/main/youtubetv/extra/YouTubeonTV-linux-x64.zip
if [ -z "$app_url" ]; then
    echo "Error: Failed to fetch the download URL for YouTube TV."
    echo "Debugging information:"
    curl -s https://github.com/foclabroc/toolbox/raw/refs/heads/main/youtubetv/extra/YouTubeonTV-linux-x64.zip
    exit 1
fi

# Download the archive
echo -e "\e[1;34mInstallation de YouTube TV...\e[1;37m"
rm -rf /userdata/system/pro/youtubetv 2>/dev/null
rm -rf /userdata/system/pro/youtube-tv 2>/dev/null
mkdir -p "/userdata/system/pro/youtubetv"
app_dir="/userdata/system/pro/youtubetv"
temp_dir="$app_dir/temp"
mkdir -p "$temp_dir"
wget -q --show-progress -O "$temp_dir/youtube-tv.zip" "$app_url"

if [ $? -ne 0 ]; then
    echo "Failed to download YouTube TV archive."
    exit 1
fi

# Extract the downloaded archive
echo "Extracting YouTube TV files..."
mkdir -p "$app_dir"
total_size=$(stat -c %s "$temp_dir/youtube-tv.zip")
# Extraire avec une barre de progression
pv -p -s "$total_size" "$temp_dir/youtube-tv.zip" | unzip -o -d "$temp_dir/youtube-tv-extracted" >/dev/null
mv "$temp_dir/youtube-tv-extracted/"*/* "$app_dir"
chmod a+x "$app_dir/YouTubeonTV"

# Cleanup temp files
rm -rf "$temp_dir"
echo "Extraction complete. Files moved to $app_dir."

# make Launcher
cat << EOF > "$app_dir/Launcher"
#!/bin/bash 
unclutter-remote -s
sed -i "s,!appArgs.disableOldBuildWarning,1 == 0,g" /userdata/system/pro/youtubetv/resources/app/lib/main.js 2>/dev/null && mkdir /userdata/system/pro/youtubetv/home 2>/dev/null; mkdir /userdata/system/pro/youtubetv/config 2>/dev/null; mkdir /userdata/system/pro/youtubetv/roms 2>/dev/null; LD_LIBRARY_PATH="/userdata/system/pro/.dep:${LD_LIBRARY_PATH}" HOME=/userdata/system/pro/youtubetv/home XDG_CONFIG_HOME=/userdata/system/pro/youtubetv/config QT_SCALE_FACTOR="1" GDK_SCALE="1" XDG_DATA_HOME=/userdata/system/pro/youtubetv/home DISPLAY=:0.0 /userdata/system/pro/youtubetv/YouTubeonTV --no-sandbox --test-type "${@}"
EOF
dos2unix "$app_dir/Launcher"
chmod a+x "$app_dir/Launcher"

# .DEP FILES
mkdir -p "/userdata/system/pro/.dep"
wget -q --show-progress -O "/userdata/system/pro/.dep/dep.zip" "https://github.com/foclabroc/toolbox/raw/refs/heads/main/gparted/extra/dep.zip";
cd /userdata/system/pro/.dep/
unzip -o -qq /userdata/system/pro/.dep/dep.zip 2>/dev/null

# Create a launcher script using the original command
echo "Creating YouTube TV script in Ports..."
echo "Création d'un script YouTube TV dans Ports..."
sleep 3
ports_dir="/userdata/roms/ports"
mkdir -p "$ports_dir"

# PURGE PORTS DIR
rm $ports_dir/YouTubeTV.sh 2>/dev/null
rm $ports_dir/YoutubeTV.sh 2>/dev/null
rm $ports_dir/YoutubeTV.sh.keys 2>/dev/null
rm $ports_dir/YouTubeTV.sh.keys 2>/dev/null

cat << EOF > "$ports_dir/YoutubeTV.sh"
#!/bin/bash
unclutter-remote -s
killall -9 YouTubeonTV && unclutter-remote -s
/userdata/system/pro/youtubetv/Launcher
EOF

chmod +x "$ports_dir/YoutubeTV.sh"

# Step 6: Download keys file
echo "Downloading keys file..."
keys_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/extra/YoutubeTV.sh.keys"
keys_file="$ports_dir/YoutubeTV.sh.keys"
curl -L -o "$keys_file" "$keys_url"

if [ $? -ne 0 ]; then
    echo "Failed to download keys file."
    exit 1
fi

echo "Keys file downloaded to $keys_file."

# Step 7: Refresh the Ports menu
echo "Refreshing Ports menu..."
curl http://127.0.0.1:1234/reloadgames

# Step 8: Add an entry to gamelist.xml
echo "Adding YouTube TV entry to gamelist.xml..."
gamelist_file="$ports_dir/gamelist.xml"
screenshot_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/extra/YoutubeTV-screenshot.png"
screenshot_path="$ports_dir/images/YoutubeTV-screenshot.png"
logo_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/extra/YoutubeTV-wheel.png"
logo_path="$ports_dir/images/YoutubeTV-wheel.png"
box_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/extra/YoutubeTV-cartridge.png"
box_path="$ports_dir/images/YoutubeTV-cartridge.png"

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

# Add the YouTube TV entry

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
    -s "/gameList/game[last()]" -t elem -n "path" -v "./YoutubeTV.sh" \
    -s "/gameList/game[last()]" -t elem -n "name" -v "Youtube TV" \
    -s "/gameList/game[last()]" -t elem -n "desc" -v "Youtube TV pour Batocera Linux. Découvrez les contenus regardés partout dans le monde : des clips musicaux du moment aux vidéos populaires sur les jeux vidéo, la mode, la beauté, les actualités, l'éducation et bien plus encore." \
    -s "/gameList/game[last()]" -t elem -n "developer" -v "Youtube" \
    -s "/gameList/game[last()]" -t elem -n "publisher" -v "Youtube" \
    -s "/gameList/game[last()]" -t elem -n "genre" -v "Divertissement" \
    -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
    -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
    -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
    -s "/gameList/game[last()]" -t elem -n "image" -v "./images/YoutubeTV-screenshot.png" \
    -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/YoutubeTV-wheel.png" \
    -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/YoutubeTV-cartridge.png" \
    "$gamelist_file"

# Refresh the Ports menu
curl http://127.0.0.1:1234/reloadgames

echo
echo -e "\e[1;32mInstallation complete! You can now launch YouTube TV from the Ports menu."
echo -e "-----------------------------------------------------------------------------------------"
echo -e "Installation terminée ! Vous pouvez désormais lancer YouTube TV depuis le menu « Ports ».\e[1;37m"
sleep 5