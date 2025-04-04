#!/bin/bash

# Définir les URLs pour les fichiers split
URL_PART1="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.002"

# Définir le répertoire de téléchargement et le chemin de destination pour l'extraction
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"
GE_CUSTOM_DIR="$EXTRACT_DIR/ge-custom"

# Créer les répertoires
mkdir -p "$DOWNLOAD_DIR" "$EXTRACT_DIR"

# Afficher un message de téléchargement
dialog --backtitle "Foclabroc Toolbox" --title "GE-Custom V40" --infobox "Téléchargement et extraction de GE-Custom V40..." 6 50
sleep 2
# Fonction de téléchargement avec affichage de la progression
download_file() {
    local url=$1
    local output=$2
    (
        wget --progress=dot "$url" -O "$output" 2>&1 | \
        while read -r line; do
            percent=$(echo "$line" | awk '/[0-9]%/ {print $2}' | tr -d '%')
            if [[ "$percent" =~ ^[0-9]+$ ]]; then
                echo $percent
            fi
        done
    ) | dialog --gauge "Téléchargement en cours..." 10 70 0
    if [ $? -ne 0 ]; then
        dialog --title "Erreur" --msgbox "Échec du téléchargement de $output." 6 50
        exit 1
    fi
}

# Télécharger les fichiers
download_file "$URL_PART1" "$DOWNLOAD_DIR/ge-customv40.tar.xz.001"
download_file "$URL_PART2" "$DOWNLOAD_DIR/ge-customv40.tar.xz.002"

# Combiner les fichiers
cat "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" > "$DOWNLOAD_DIR/ge-customv40.tar.xz"
if [ $? -ne 0 ]; then
    dialog --title "Erreur" --msgbox "Échec de l'assemblage des fichiers." 6 50
    exit 1
fi

# Décompression du .xz pour obtenir le .tar
dialog --gauge "Décompression du fichier .xz en cours..." 10 70 0
unxz -f "$DOWNLOAD_DIR/ge-customv40.tar.xz"
if [ $? -ne 0 ]; then
    dialog --title "Erreur" --msgbox "Échec de la décompression du fichier .xz." 6 50
    exit 1
fi

# Extraction du .tar dans le dossier de destination
dialog --gauge "Extraction du fichier .tar en cours..." 10 70 0
tar -xf "$DOWNLOAD_DIR/ge-customv40.tar" -C "$EXTRACT_DIR"
if [ $? -ne 0 ]; then
    dialog --title "Erreur" --msgbox "Échec de l'extraction du fichier .tar." 6 50
    exit 1
fi

# Suppression des fichiers temporaires
rm -rf "$DOWNLOAD_DIR"

# Afficher un message de fin
dialog --backtitle "Foclabroc Toolbox" --title "GE-Custom V40" --msgbox "Téléchargement et extraction de Ge-custom V40 terminés avec succès !" 6 50
