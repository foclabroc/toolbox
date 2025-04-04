#!/bin/bash

# Définir les URLs pour les fichiers split
URL_PART1="https://github.com/foclabroc/toolbox/blob/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://github.com/foclabroc/toolbox/blob/main/wine-tools/ge-customv40.tar.xz.002"

# Définir le répertoire de téléchargement et le chemin de destination pour l'extraction
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"
GE_CUSTOM_DIR="$EXTRACT_DIR/ge-custom"

# Créer les répertoires
mkdir -p "$DOWNLOAD_DIR" "$EXTRACT_DIR"

# Afficher un message de téléchargement
dialog --backtitle "Foclabroc Toolbox" --title "GE-Custom V40" --infobox "Téléchargement et extraction de GE-Custom V40..." 6 50

# Fonction de téléchargement avec progression
download_file() {
    local url=$1
    local output=$2
    wget --progress=bar:force:noscroll -O "$output" "$url" 2>&1 | \
    dialog --gauge "Téléchargement en cours..." 10 70 0
}

# Télécharger les fichiers
download_file "$URL_PART1" "$DOWNLOAD_DIR/ge-customv40.tar.xz.001"
download_file "$URL_PART2" "$DOWNLOAD_DIR/ge-customv40.tar.xz.002"

# Combiner les fichiers
cat "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" > "$DOWNLOAD_DIR/ge-customv40.tar.xz"

# Supprimer l'ancien dossier GE-Custom s'il existe
if [ -d "$GE_CUSTOM_DIR" ]; then
    rm -rf "$GE_CUSTOM_DIR"
fi

# Fonction d'extraction avec progression
extract_file() {
    local file=$1
    local target_dir=$2
    tar -xf "$file" -C "$target_dir" | \
    dialog --gauge "Extraction en cours..." 10 70 0
}

# Extraire le fichier
extract_file "$DOWNLOAD_DIR/ge-customv40.tar.xz" "$EXTRACT_DIR"

# Afficher un message de fin
dialog --backtitle "Foclabroc Toolbox" --title "GE-Custom V40" --msgbox "Téléchargement et extraction terminés avec succès !" 6 50
