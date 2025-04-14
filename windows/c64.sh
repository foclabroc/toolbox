#!/bin/bash

# Définition des variables
URL_TELECHARGEMENT="https://github.com/foclabroc/toolbox/releases/download/Fichiers/Celeste64-v1.1.1-Linux-x64.zip"
DOSSIER_DESTINATION="/userdata/roms/ports/celeste64"
CHEMIN_SCRIPT="/userdata/roms/ports/Celeste64.sh"
FICHIER_ZIP="/tmp/Celeste64.zip"

# Fonction de chargement
afficher_barre_progression() {
    (
        echo "10"; sleep 0.5
        mkdir -p "$DOSSIER_DESTINATION"
        echo "20"; sleep 0.5
        curl -L --progress-bar "$URL_TELECHARGEMENT" -o "$FICHIER_ZIP" > /dev/null 2>&1
        echo "60"; sleep 0.5
        unzip -o "$FICHIER_ZIP" -d "$DOSSIER_DESTINATION" > /dev/null 2>&1
        echo "80"; sleep 0.5
        rm "$FICHIER_ZIP"
        echo "90"; sleep 0.5
        cat << EOF > "$CHEMIN_SCRIPT"
#!/bin/bash
cd "$DOSSIER_DESTINATION"
DISPLAY=:0.0 ./Celeste64
EOF
        chmod +x "$CHEMIN_SCRIPT"
        echo "100"; sleep 0.5
    ) |
    dialog --title "Installation de Celeste64" --gauge "\nTéléchargement et installation en cours..." 10 60 0 2>&1 >/dev/tty
}

# Exécution
afficher_barre_progression

# Message de fin
dialog --title "Installation terminée" --msgbox "\nCeleste64 a été ajouté dans les Ports !\n\nPensez à mettre à jour vos gamelists pour le voir apparaître dans le menu." 10 50 2>&1 >/dev/tty

clear
