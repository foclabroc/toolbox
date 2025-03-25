#!/bin/bash

clear
# Définir l'URL du fichier ZIP
ZIP_URL="https://github.com/foclabroc/toolbox/releases/download/Fichiers/kodi.zip"

# Définir le chemin du dossier Kodi
KODI_DIR="/userdata/system/.kodi"

# Affichage d'une boîte de dialogue de confirmation
dialog --backtitle "Foclabroc Toolbox" --title "Pack Kodi" \
--yesno "\nScript d'installation pack Kodi Foclabroc. (Vstream; IPTV...)

Attention : l'installation du pack supprimera tout le dossier .kodi 
y compris tous vos paramètres actuels de Kodi, et les remplacera par ceux de mon pack.

\nÊtes-vous sûr de vouloir installer le pack ?" 15 60

# Vérifier la réponse de l'utilisateur
if [ $? -ne 0 ]; then
    echo "Installation annulée."
    exit 0
fi

# Vérifier si le dossier Kodi existe, puis le supprimer
if [ -d "$KODI_DIR" ]; then
    echo "Suppression du dossier .Kodi..."
    rm -rf "$KODI_DIR"
    echo "Dossier supprimé."
fi

# Télécharger le fichier ZIP
echo "Téléchargement du fichier ZIP..."
wget -q --show-progress -O /tmp/kodi.zip "$ZIP_URL"

# Vérifier si le téléchargement a réussi
if [ $? -eq 0 ]; then
    echo "Téléchargement réussi. Extraction en cours..."
    unzip -o /tmp/kodi.zip -d /userdata/system/ | pv -lep -s $(unzip -l /tmp/kodi.zip | wc -l) > /dev/null
    echo "Extraction terminée."
    sleep 2
else
    echo "Échec du téléchargement."
    rm -f /tmp/kodi.zip
    exit 1
fi

# Nettoyage du fichier ZIP
echo "Nettoyage des fichiers temporaire..."
sleep 1
rm -f /tmp/kodi.zip

echo "Opération terminée."
sleep 2

# Affichage du message de confirmation
dialog --backtitle "Foclabroc Toolbox" --title "Terminé" \
--msgbox "Installation du pack Kodi terminée avec succès." 6 50
