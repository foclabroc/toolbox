#!/bin/bash

# Définir les URLs pour les fichiers split
URL_PART1="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/ge-customv40.tar.xz.002"

# Définir le répertoire de téléchargement et le chemin de destination pour l'extraction
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"

# Créer les répertoires
mkdir -p "$DOWNLOAD_DIR" "$EXTRACT_DIR"

# Afficher un message de téléchargement
dialog --title "GE-Custom V40" --msgbox "Téléchargement et extraction de GE-Custom V40..." 6 50

# Fonction pour afficher la barre de progression
function download_file {
    local url="$1"
    local output="$2"
    local file_size
    local downloaded=0

    # Obtenir la taille du fichier
    file_size=$(curl -sI "$url" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r')

    # Télécharger le fichier avec une barre de progression
    curl -Ls --progress-bar "$url" -o "$output" 2>&1 >/dev/tty | while read -r line; do
        # Calculer la progression en fonction des octets téléchargés
        downloaded=$((downloaded + $(echo "$line" | awk '{print $1}')))
        progress=$((downloaded * 100 / file_size))
        dialog --gauge "Téléchargement de GE-Custom V40 en cours..." 6 50 "$progress"
    done
}

# Télécharger les fichiers split
if ! download_file "$URL_PART1" "$DOWNLOAD_DIR/ge-customv40.tar.xz.001"; then
    dialog --title "Erreur" --msgbox "Erreur : Échec du téléchargement de la première partie." 6 50 2>&1 >/dev/tty
    exit 1
fi
if ! download_file "$URL_PART2" "$DOWNLOAD_DIR/ge-customv40.tar.xz.002"; then
    dialog --title "Erreur" --msgbox "Erreur : Échec du téléchargement de la deuxième partie." 6 50 2>&1 >/dev/tty
    exit 1
fi

# Combiner les fichiers dans une seule archive
cd "$DOWNLOAD_DIR"
cat ge-customv40.tar.xz.001 ge-customv40.tar.xz.002 > ge-customv40.tar.xz 2>&1 >/dev/tty

# Vérifier que le fichier combiné existe
if [[ ! -f "ge-customv40.tar.xz" ]]; then
    dialog --title "Erreur" --msgbox "Erreur : Impossible de combiner les fichiers." 6 50
    exit 1
fi

# Décompresser le fichier .xz avec une barre de progression
xz -d ge-customv40.tar.xz 2>&1 >/dev/tty &
XZ_PID=$!

# Afficher la barre de progression pendant la décompression
while kill -0 $XZ_PID 2>/dev/null; do
    sleep 1
    dialog --gauge "Décompression de GE-Custom V40 en cours..." 6 50 50
done

# Vérifier que le fichier .tar décompressé existe
if [[ ! -f "ge-customv40.tar" ]]; then
    dialog --title "Erreur" --msgbox "Erreur : La décompression a échoué." 6 50
    exit 1
fi

# Extraire l'archive .tar avec une barre de progression
echo "Extraction de l'archive..."
tar -xf ge-customv40.tar -C "$EXTRACT_DIR" --checkpoint=1000 --checkpoint-action=dot 2>&1 >/dev/tty |
    while read -r line; do
        dialog --gauge "Décompression de GE-Custom V40 en cours..." 6 50 $((RANDOM % 100))
    done

# Nettoyage des fichiers temporaires
rm -rf "$DOWNLOAD_DIR" ge-customv40.tar

# Vérification de l'extraction réussie
dialog --title "Succès" --msgbox "Extraction terminée ! Les fichiers sont dans $EXTRACT_DIR." 6 50


