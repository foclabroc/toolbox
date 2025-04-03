#!/bin/bash

# API endpoint pour récupérer les versions
REPO_URL="https://api.github.com/repos/Kron4ek/Wine-Builds/releases?per_page=300"

# Répertoire d'installation des versions Wine personnalisées
INSTALL_DIR="/userdata/system/wine/custom/"
mkdir -p "$INSTALL_DIR"

# Récupération des versions disponibles
(
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nRécupération des versions de Wine Vanilla/Regular..." 5 60
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
    i=0

    # Construire la liste des options (index et name)
    while IFS= read -r line; do
        tag=$(echo "$line" | jq -r '.name')
        tag="(Vanilla)${tag}"
        options+=("$i" "$tag")
        ((i++))
    done < <(echo "$release_data" | jq -c '.[]')

    # Vérifier que des options existent
    if [[ ${#options[@]} -eq 0 ]]; then
        echo -e "Erreur : aucune version disponible."
        exit 1
    fi

    # Affichage du menu et récupération du choix
    choice=$(dialog --clear --backtitle "Foclabroc Toolbox" --title "Wine-vanilla" --menu "\nChoisissez une version à télécharger :\n " 22 76 16 "${options[@]}" 2>&1 >/dev/tty)

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
	version=$(echo "$release_data" | jq -r ".[$choice].name" 2>/dev/null)
	url=$(echo "$release_data" | jq -r ".[$choice].assets[] | select(.name | endswith(\"amd64.tar.xz\")).browser_download_url" | head -n1 2>/dev/null)

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
	) | dialog --backtitle "Foclabroc Toolbox" --gauge "\nTéléchargement et extraction de ${version} Patientez..." 8 70 0 2>&1 >/dev/tty

	# Vérification du téléchargement
	if [ ! -f "$ARCHIVE" ]; then
		echo -e "Erreur : échec du téléchargement de ${version}."
		sleep 2
		continue
	fi

######################################################################
    # Taille totale de l'archive
    TOTAL_FILES=$(tar -tf "$ARCHIVE" | wc -l)
    if [[ "$TOTAL_FILES" -eq 0 ]]; then
        dialog --msgbox "Erreur : archive vide ou illisible." 7 60
        exit 1
    fi

    # Création du FIFO pour suivre l'extraction
    TMP_PROGRESS="/tmp/extract_progress"
    rm -f "$TMP_PROGRESS"
    mkfifo "$TMP_PROGRESS"

    # Processus d'extraction en arrière-plan
    COUNT=0
    (
        tar --strip-components=1 -xJf "$ARCHIVE" -C "$WINE_DIR" --checkpoint=10 --checkpoint-action=echo="%u" > "$TMP_PROGRESS" 2>/dev/null &
        TAR_PID=$!

        while read -r CHECKPOINT; do
            COUNT=$((COUNT + 10))  
            PERCENT=$((COUNT * 100 / TOTAL_FILES))
            echo "$PERCENT"
        done < "$TMP_PROGRESS"
        
        wait "$TAR_PID"
        echo 100
    ) | dialog --gauge "Extraction de ${version} en cours..." 7 60 0 2>&1 >/dev/tty

    rm -f "$TMP_PROGRESS"

    if [ $? -eq 0 ]; then
        rm "$ARCHIVE"
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nTéléchargement et extraction de ${version} terminé avec succès." 7 60
        sleep 2
    else
        rm "$ARCHIVE"
        dialog --msgbox "Erreur lors de l'extraction." 7 60
    fi
done
