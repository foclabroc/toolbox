#!/bin/bash

# API endpoint pour récupérer les versions
REPO_URL="https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases?per_page=100"

# Répertoire d'installation des versions Wine personnalisées
INSTALL_DIR="/userdata/system/wine/custom/"
mkdir -p "$INSTALL_DIR"

# Récupération des versions disponibles
(
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nRécupération des versions de Wine GE-Custom..." 5 60
  sleep 1
) 2>&1 >/dev/tty
release_data=$(curl -s "$REPO_URL")

# Vérification du succès de la requête
if [[ $? -ne 0 || -z "$release_data" ]]; then
    echo -e "Erreur : impossible de récupérer les informations depuis GitHub."
    exit 1
fi

while true; do
    # Préparation des options pour le menu
    options=()
    i=1

    # Construire la liste des options (index et name) avec ajout de "-staging-tkg"
    while IFS= read -r line; do
        tag=$(echo "$line" | jq -r '.name')
        # Ajouter "-staging-tkg" à la version
        options+=("$i" "$tag")
        ((i++))
    done < <(echo "$release_data" | jq -c '.[]')

    # Vérifier que des options existent
    if [[ ${#options[@]} -eq 0 ]]; then
        echo -e "Erreur : aucune version disponible."
        exit 1
    fi

    # Affichage du menu et récupération du choix
    choice=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Wine-GE-Custom" --menu "\nChoisissez une version à télécharger :\n " 22 76 16 "${options[@]}" 2>&1 >/dev/tty)

    # Nettoyage de l'affichage
    clear

# Si l'utilisateur appuie sur "Annuler" (retourne 1)
	if [[ $? -eq 1 ]]; then
		(
			dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60
			sleep 1
		) 2>&1 >/dev/tty
		curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
		exit 0
	fi

# Si l'utilisateur annule la sélection (choix vide)
	if [[ -z "$choice" ]]; then
		(
			dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60
			sleep 1
		) 2>&1 >/dev/tty
		curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
		exit 0
	fi

    # Vérification que le choix est bien un nombre
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e "Erreur : choix invalide ($choice)."
        sleep 2
        continue
    fi

# Extraire la version et l'URL
	version=$(echo "$release_data" | jq -r ".[$choice-1].name" 2>/dev/null)
	# version="${version}-tkg"
    url=$(echo "$release_data" | jq -r ".[$choice-1].assets[] | select(.name | endswith(\"x86_64.tar.xz\")).browser_download_url" | head -n1 2>/dev/null)

# Vérifier si la version est bien récupérée
	if [[ -z "$version" || -z "$url" ]]; then
		echo -e "Erreur : impossible de récupérer les informations pour la version $choice."
		sleep 2
		continue
	fi

# Sauvegarder la version dans un fichier temporaire
	echo -e "$version" > /tmp/version.txt

# Récupérer la version depuis le fichier temporaire pour l'utiliser plus tard
	version=$(cat /tmp/version.txt)

	response=$(dialog --backtitle "Foclabroc Toolbox" --yesno "\nVoulez-vous télécharger et installer ${version} ?" 7 60 2>&1 >/dev/tty)
	if [[ $? -ne 0 ]]; then
		(
			dialog --backtitle "Foclabroc Toolbox" --infobox "\nTéléchargement de ${version} annulé." 5 60
			sleep 1
		) 2>&1 >/dev/tty
		continue
	fi

	# Création du répertoire de destination
	WINE_DIR="${INSTALL_DIR}${version}"
	mkdir -p "$WINE_DIR"
	cd "${WINE_DIR}"
	clear

	# Préparer le fichier de téléchargement
	ARCHIVE="${WINE_DIR}/${version}.tar.xz"

	# Télécharger le fichier avec wget et afficher la progression dans une boîte dialog
	(
		wget --tries=10 --no-check-certificate --no-cache --no-cookies --show-progress -O "$ARCHIVE" "$url" 2>&1 | \
		while read -r line; do
			# Si la ligne contient un pourcentage, extrait la valeur
			if [[ "$line" =~ ([0-9]+)% ]]; then
				PERCENT=${BASH_REMATCH[1]}  # Récupère le pourcentage
				# Envoie la progression à la boîte dialog --gauge
				echo "$PERCENT"  # La progression est envoyée à la boîte de dialogue
			fi
		done
	) | dialog --backtitle "Foclabroc Toolbox" --gauge "\nTéléchargement et extraction de ${version} Patientez..." 8 75 0 2>&1 >/dev/tty

	# Vérification du téléchargement
	if [ ! -f "$ARCHIVE" ]; then
		echo -e "Erreur : échec du téléchargement de ${version}."
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
    if tar --strip-components=1 -xJf "$ARCHIVE" -C "$WINE_DIR" | while read line; do
        COUNT=$((COUNT + 1))
        PERCENT=$((COUNT * 100 / TOTAL_FILES))
    done; then
        rm "$ARCHIVE"
        sleep 1
    else
        rm "$ARCHIVE"
    fi
    (
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nTéléchargement et extraction du runner ${version} terminé avec succès " 6 60
      sleep 1
    ) 2>&1 >/dev/tty
    sleep 2
done
