#!/bin/bash

# Définition des URLs des archives en fonction de la version
URL_40="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d.zip"
URL_41="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d-41.zip"
URL_42="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d-42.zip"
# URL_43="https://github.com/foclabroc/toolbox/releases/download/Fichiers/3d-43.zip"
URL_43="https://foclabroc.freeboxos.fr:55973/share/3g4E1VIWsUojpQKm/3d-43.zip"

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
elif [ "$VERSION" -eq 42 ]; then
    ARCHIVE_URL="$URL_42"
elif [ "$VERSION" -ge 43 ]; then
    ARCHIVE_URL="$URL_43"
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
rm -f /userdata/system/configs/evmapy/3dnes.keys
rm -f /userdata/system/configs/emulationstation/es_features_3dnes.cfg
rm -f /userdata/system/configs/emulationstation/es_systems_3dnes.cfg
rm -rf /userdata/system/3dnes
rm -rf /userdata/system/nes3d
rm -rf /userdata/roms/nes3d
rm -rf /userdata/system/wine-bottles/3dnes
rm -rf /userdata/system/wine-bottles/nes3d

# Vérification de l'espace disque
ARCHIVE_SIZE_MB=1800
REQUIRED_SPACE_MB=$((ARCHIVE_SIZE_MB * 2 + 200))

# Récupérer l’espace libre sur /userdata (en Mo)
FREE_SPACE_MB=$(df -m /userdata | awk 'NR==2 {print $4}')

if [ "$FREE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
    dialog --backtitle "Foclabroc Toolbox" --title "Espace disque insuffisant" \
    --msgbox "Espace disque disponible : ${FREE_SPACE_MB} Mo\n\nEspace requis : ${REQUIRED_SPACE_MB} Mo\n\nVeuillez libérer de l’espace sur /userdata." 10 60
    exit 1
fi

#Lancement telechargement
echo "Téléchargement de l'archive pour version : $VERSION ..."
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
--msgbox "Installation du pack Nes3D terminée avec succès." 10 70
