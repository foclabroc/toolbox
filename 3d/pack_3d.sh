#!/bin/bash

# Définition des URLs des archives en fonction de la version
URL_40="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d.zip"
URL_41="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d-41.zip"
URL_42="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d-42.zip"

clear

# Détecter la version de Batocera
VERSION=$(batocera-es-swissknife --version | awk '{print $1}' | sed -E 's/^([0-9]+).*/\1/')
echo "Version de Batocera détectée : $VERSION"
sleep 2

# Déterminer l'URL en fonction de la version
if [ "$VERSION" -le 40 ]; then
    ARCHIVE_URL="$URL_40"
elif [ "$VERSION" -eq 41 ]; then
    ARCHIVE_URL="$URL_41"
elif [ "$VERSION" -ge 42 ]; then
    ARCHIVE_URL="$URL_42"
else
    echo "Version non prise en charge."
    exit 1
fi

# Nom du fichier
ARCHIVE_NAME=$(basename "$ARCHIVE_URL")

# Chemin de destination
DESTINATION="/userdata/"

# Suppression des anciens dossiers
echo "Suppression des anciens fichiers..."
rm -rf /userdata/system/3dnes
rm -rf /userdata/system/nes3d
rm -rf /userdata/roms/nes3d
rm -rf /userdata/system/wine-bottles/3dnes
rm -rf /userdata/system/wine-bottles/nes3d

echo "Téléchargement de l'archive..."
wget -q --show-progress -O "$DESTINATION$ARCHIVE_NAME" "$ARCHIVE_URL"

if [ $? -ne 0 ]; then
    echo "Échec du téléchargement."
    exit 1
fi

# Vérifier si le téléchargement a réussi
if [ $? -eq 0 ]; then
    echo "Extraction en cours..."
    TOTAL_FILES=$(unzip -l $DESTINATION$ARCHIVE_NAME | wc -l)
    COUNT=0

unzip -o "$DESTINATION$ARCHIVE_NAME" -d "$DESTINATION" | while read line; do
    COUNT=$((COUNT + 1))
    PERCENT=$((COUNT * 100 / TOTAL_FILES))
    echo -ne "Progression : $PERCENT%\r"
done

echo -e "\nExtraction terminée."
    sleep 1
else
    echo "Échec du téléchargement."
    rm -f $DESTINATION$ARCHIVE_NAME
    exit 1
fi

# Nettoyage du fichier ZIP
echo "Nettoyage des fichiers temporaire..."
sleep 1
rm -f $DESTINATION$ARCHIVE_NAME

#actualisation liste des jeux
echo "Actualisation de la liste des jeux"
curl http://127.0.0.1:1234/reloadgames
echo "Opération terminée."
sleep 2

# Affichage du message de confirmation
dialog --backtitle "Foclabroc Toolbox" --title "Terminé" \
--msgbox "Installation du pack Nes3D terminée avec succès." 6 50
