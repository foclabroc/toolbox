#!/bin/bash

# Définir les URLs pour les fichiers split
URL_PART1="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.002"

# Define the download directory and target extraction path
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"

# Create the directories
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

# Download the split files
dialog --backtitle "Foclabroc Toolbox" --infobox "\nTéléchargement de ge-custom v40 en cours..." 4 55
curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" "$URL_PART1" --progress-bar
curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" "$URL_PART2" --progress-bar

# Combine the files into a single archive
cd "$DOWNLOAD_DIR"
dialog --backtitle "Foclabroc Toolbox" --infobox "\nAssemblage des 2 parties en cours..." 4 55
sleep 1
cat ge-customv40.tar.xz.001 ge-customv40.tar.xz.002 > ge-customv40.tar.xz

# Verify the combined file exists
if [[ ! -f "ge-customv40.tar.xz" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de l'assemblage des 2 parties !!!" 4 55
	sleep 2
    exit 1
fi

# Decompress the .xz file
dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du .xz en cours..." 4 55
xz -d ge-customv40.tar.xz

# Verify the decompressed file exists
if [[ ! -f "ge-customv40.tar" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de la décompression du .xz !!!" 4 55
    exit 1
fi

# Extract the .tar archive
dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du .tar en cours..." 4 55
tar -xf ge-customv40.tar -C "$EXTRACT_DIR"

# Check if extraction was successful
if [[ $? -eq 0 ]]; then
	dialog --backtitle "Foclabroc Toolbox" --infobox "Installation de ge-custom V40 terminé avec succès dans $EXTRACT_DIR." 5 60
	sleep 2
else
	dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de l'Installation de ge-custom V40 !!!" 4 55
    exit 1
fi

# Clean up temporary files
rm -rf "$DOWNLOAD_DIR"
