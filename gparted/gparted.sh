#!/bin/bash

# Define variables
APPNAME="GParted"
REPO_BASE_URL="https://github.com/foclabroc/toolbox/raw/refs/heads/main/gparted/extra/"
AMD_SUFFIX="gparted.AppImage"
ARM_SUFFIX=""
ICON_URL="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/gparted/extra/icon.png"

# Directories
ADDONS_DIR="/userdata/system/pro"
CONFIGS_DIR="/userdata/system/configs"
DESKTOP_DIR="/usr/share/applications"
CUSTOM_SCRIPT="/userdata/system/custom.sh"
APP_CONFIG_DIR="${CONFIGS_DIR}/${APPNAME,,}"
PERSISTENT_DESKTOP="${APP_CONFIG_DIR}/${APPNAME,,}.desktop"
DESKTOP_FILE="${DESKTOP_DIR}/${APPNAME,,}.desktop"

# Ensure directories exist
mkdir -p "$APP_CONFIG_DIR" "$ADDONS_DIR/${APPNAME,,}/extra"

# Download the AppImage
appimage_url="${REPO_BASE_URL}${AMD_SUFFIX}"
echo -e "\e[1;34mInstallation de Gparted en cours...\e[1;37m"
if ! wget -q --show-progress -O "$ADDONS_DIR/${APPNAME,,}/${APPNAME,,}.AppImage" "$appimage_url"; then
    echo "Failed to download $APPNAME AppImage. Exiting."
    exit 1
fi
chmod a+x "$ADDONS_DIR/${APPNAME,,}/${APPNAME,,}.AppImage"

# Download the application icon
if ! wget -q --show-progress -O "$ADDONS_DIR/${APPNAME,,}/extra/${APPNAME,,}-icon.png" "$ICON_URL"; then
    echo "Failed to download $APPNAME icon. Exiting."
    exit 1
fi

if ! wget -q --show-progress -O "$ADDONS_DIR/${APPNAME,,}/Launcher" "https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/gparted/extra/Launcher"; then
    echo "Failed to download $APPNAME launcher. Exiting."
    exit 1
fi
chmod +x "$ADDONS_DIR/${APPNAME,,}/Launcher"
# Create persistent desktop entry
cat <<EOF > "$PERSISTENT_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APPNAME
Exec=$ADDONS_DIR/${APPNAME,,}/Launcher
Icon=$ADDONS_DIR/${APPNAME,,}/extra/${APPNAME,,}-icon.png
Terminal=false
Categories=Utility;batocera.linux;
EOF
chmod +x "$PERSISTENT_DESKTOP"
cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Create restore script
cat <<EOF > "${APP_CONFIG_DIR}/restore_desktop_entry.sh"
#!/bin/bash
if [ ! -f "$DESKTOP_FILE" ]; then
    cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
fi
EOF
chmod +x "${APP_CONFIG_DIR}/restore_desktop_entry.sh"

mkdir -p "$ADDONS_DIR/.dep"
wget -q --show-progress -O "$ADDONS_DIR/.dep/dep.zip" "https://github.com/foclabroc/toolbox/raw/refs/heads/main/gparted/extra/dep.zip";
cd $ADDONS_DIR/.dep/
unzip -o -qq $ADDONS_DIR/.dep/dep.zip 2>/dev/null
# Add restore script to startup
if ! grep -q "${APP_CONFIG_DIR}/restore_desktop_entry.sh" "$CUSTOM_SCRIPT"; then
    echo "\"${APP_CONFIG_DIR}/restore_desktop_entry.sh\" &" >> "$CUSTOM_SCRIPT"
fi

echo -e "\e[1;32mInstallation complete! You can now launch Gparted from F1 menu."
echo -e "-----------------------------------------------------------------------------------------"
echo -e "Installation terminée ! Vous pouvez désormais lancer Gparted depuis le menu « F1 applications ».\e[1;37m"
sleep 5
