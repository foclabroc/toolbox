#!/bin/bash

clear

# API endpoint pour récupérer les versions
REPO_URL="https://api.github.com/repos/Kron4ek/Wine-Builds/releases?per_page=300"

# Répertoire d'installation des versions Wine personnalisées
INSTALL_DIR="/userdata/system/wine/custom/"
mkdir -p "$INSTALL_DIR"

# Récupération des versions disponibles
dialog --infobox "\nRécupération des versions de Wine Vanilla/Regular..." 5 60
release_data=$(curl -s "$REPO_URL")

# Vérification du succès de la requête
if [[ $? -ne 0 || -z "$release_data" ]]; then
    echo "Erreur : impossible de récupérer les informations depuis GitHub."
    exit 1
fi

while true; do
    # Préparation des options pour le menu
    options=()
    i=0

    # Construire la liste des options (index et name)
    while IFS= read -r line; do
        tag=$(echo "$line" | jq -r '.name')
        options+=("$i" "$tag")
        ((i++))
    done < <(echo "$release_data" | jq -c '.[]')

    # Vérifier que des options existent
    if [[ ${#options[@]} -eq 0 ]]; then
        echo "Erreur : aucune version disponible."
        exit 1
    fi

    # Affichage du menu et récupération du choix
    choice=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Wine-proton" --menu "\nChoisissez une version à télécharger :\n " 22 76 16 "${options[@]}" 2>&1 >/dev/tty)

    # Nettoyage de l'affichage
    clear

    # Si l'utilisateur appuie sur "Annuler" (retourne 1)
    if [[ $? -eq 1 ]]; then
        dialog --infobox "\nRetour Menu Wine Tools..." 5 60
        sleep 2
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
        exit 0
    fi

    # Si l'utilisateur annule la sélection (choix vide)
    if [[ -z "$choice" ]]; then
        dialog --infobox "\nRetour Menu Wine Tools..." 5 60
        sleep 2
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
        exit 0
    fi

    # Vérification que le choix est bien un nombre
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Erreur : choix invalide ($choice)."
        sleep 2
        continue
    fi

    # Récupérer la version et l'URL
    version=$(echo "$release_data" | jq -r ".[$choice].name" 2>/dev/null)
    url=$(echo "$release_data" | jq -r ".[$choice].assets[] | select(.name | endswith(\"amd64.tar.xz\")).browser_download_url" | head -n1 2>/dev/null)

    # Vérifier que les infos sont bien récupérées
    if [[ -z "$version" || -z "$url" ]]; then
        echo "Erreur : impossible de récupérer les informations pour la version $choice."
        sleep 2
        continue
    fi

    # Demande de confirmation avant téléchargement
    dialog --yesno "\nVoulez-vous télécharger et installer ${version} ?" 7 60
    response=$?

    if [[ $response -ne 0 ]]; then
        echo "Téléchargement annulé pour ${version}."
        sleep 1
        continue
    fi

    # Création du répertoire de destination
    WINE_DIR="${INSTALL_DIR}${version}"
    mkdir -p "$WINE_DIR"
    cd "${WINE_DIR}"
    clear

    # Téléchargement du fichier avec reprise possible
    echo "Téléchargement de ${version}..."
    wget -q --tries=10 --no-check-certificate --no-cache --no-cookies --show-progress -O "${WINE_DIR}/${version}.tar.xz" "$url"

    # Vérification du téléchargement
    if [ ! -f "${WINE_DIR}/${version}.tar.xz" ]; then
        echo "Erreur : échec du téléchargement de ${version}."
        sleep 2
        continue
    fi

    # Taille de l'archive pour calcul du pourcentage
    ARCHIVE="${WINE_DIR}/${version}.tar.xz"
    SIZE=$(du -b "$ARCHIVE" | cut -f1)

    # Total de fichiers à extraire (via tar -tf)
    TOTAL_FILES=$(tar -tf "$ARCHIVE" | wc -l)
    COUNT=0

    # Extraction avec progression
    echo "Décompression de ${version} dans ${WINE_DIR}..."
    if tar --strip-components=1 -xJf "$ARCHIVE" -C "$WINE_DIR" | while read line; do
        COUNT=$((COUNT + 1))
        PERCENT=$((COUNT * 100 / TOTAL_FILES))
        echo -ne "Décompression : $PERCENT%\r"
    done; then
        rm "$ARCHIVE"
        echo -e "\nDécompression réussie et archive supprimée."
        sleep 1
    else
        echo "Erreur : extraction de ${version} échouée."
        rm "$ARCHIVE"
    fi

    echo "Installation de ${version} terminée."
    echo "Pour l'utiliser, selectionnez le dans les options avancées windows -> runner."
    sleep 2
done
