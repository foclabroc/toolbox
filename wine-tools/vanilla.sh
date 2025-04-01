#!/bin/bash

# API endpoint pour récupérer les versions
REPO_URL="https://api.github.com/repos/Kron4ek/Wine-Builds/releases?per_page=300"

# Répertoire d'installation des versions Wine personnalisées
INSTALL_DIR="/userdata/system/wine/custom/"
mkdir -p "$INSTALL_DIR"

# Récupération des versions disponibles
echo "Récupération des versions de Wine..."
release_data=$(curl -s "$REPO_URL")

# Vérification du succès de la requête
if [[ $? -ne 0 || -z "$release_data" ]]; then
    echo "Erreur : impossible de récupérer les informations depuis GitHub."
    exit 1
fi

while true; do
    # Préparation du menu de sélection
    cmd=(dialog --separate-output --radiolist "Sélectionnez la version de Wine/Proton à télécharger :" 22 76 16)
    options=()
    i=0

    # Construire la liste des options
    while IFS= read -r line; do
        name=$(echo "$line" | jq -r '.name')
        tag=$(echo "$line" | jq -r '.tag_name')
        description="${name} - ${tag}"
        options+=($i "$description" off)
        ((i++))
    done < <(echo "$release_data" | jq -c '.[]')

    # Affichage du menu et récupération du choix
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    # Si l'utilisateur appuie sur ESC ou annule
    if [[ -z "$choices" ]]; then
        clear
        echo "Annulation. Retour au système."
        exit 0
    fi

    # Nettoyage de l'affichage
    clear

    # Traitement des choix
    for choice in $choices; do
        version=$(echo "$release_data" | jq -r ".[$choice].tag_name")
        url=$(echo "$release_data" | jq -r ".[$choice].assets[] | select(.name | endswith(\"amd64.tar.xz\")).browser_download_url" | head -n1)

        if [[ -z "$url" ]]; then
            echo "Erreur : Aucun fichier amd64.tar.xz trouvé pour la version $version."
            sleep 2
            continue
        fi

        # Demande de confirmation avant téléchargement
        dialog --yesno "Voulez-vous télécharger et installer Wine ${version} ?" 8 60
        response=$?

        if [[ $response -ne 0 ]]; then
            echo "Téléchargement annulé pour Wine ${version}."
            sleep 2
            continue
        fi

        # Création du répertoire de destination
        WINE_DIR="${INSTALL_DIR}wine-${version}"
        mkdir -p "$WINE_DIR"

        # Téléchargement du fichier
        echo "Téléchargement de Wine ${version}..."
        wget -q --tries=10 --no-check-certificate --no-cache --no-cookies --show-progress -O "${WINE_DIR}/wine-${version}.tar.xz" "$url"

        # Vérification du téléchargement
        if [ ! -f "${WINE_DIR}/wine-${version}.tar.xz" ]; then
            echo "Erreur : Échec du téléchargement de Wine ${version}."
            sleep 2
            continue
        fi

        # Décompression
        echo "Décompression de Wine ${version}..."
        tar --strip-components=1 -xf "${WINE_DIR}/wine-${version}.tar.xz" -C "$WINE_DIR"
        
        # Suppression de l'archive
        rm "${WINE_DIR}/wine-${version}.tar.xz"
        
        echo "Installation de Wine ${version} terminée."
        sleep 2
    done
done
