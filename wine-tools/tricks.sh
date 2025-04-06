#!/bin/bash

# Boucle principale
while true; do

  # Rechercher les dossiers .wine
  wine_bottles=()

  # Recherche récursive dans /userdata/system/wine-bottles
  while IFS= read -r folder; do
    wine_bottles+=( "$folder" "" )
  done < <(find /userdata/system/wine-bottles -type d -name "*.wine")

  # Recherche dans /userdata/roms/windows
  for dir in /userdata/roms/windows/*.wine; do
    [ -d "$dir" ] || continue
    wine_bottles+=( "$dir" "" )
  done

  if [ ${#wine_bottles[@]} -eq 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nAucun dossier .wine trouvé." 10 40 2>&1 >/dev/tty
    exit 1
  fi

  # Sélection de la bouteille Wine
  selected_bottle=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection d'une bouteille Wine" \
    --menu "\nChoisissez une bouteille (.wine) pour appliquer un Winetricks :\n " 25 100 6 "${wine_bottles[@]}" 3>&1 1>&2 2>&3)

  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour au menu Wine Tools..." 5 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  # Boucle interne : appliquer plusieurs tricks sur la même bouteille
  while true; do
    FINAL_PACKAGE=""
    # Installation d'une dépendance courante VC++ ou DirectX
    dialog --backtitle "Foclabroc Toolbox" --title "Dépendances VC++ / DirectX" --yesno "\nSouhaitez-vous installer une dépendance courante comme Visual C++ ou DirectX9 ?\n\n Oui = Affichage liste tricks courant.\n\n Non = Affichage liste winetricks officiel complete.\n " 12 80 2>&1 >/dev/tty
	if [ $? -eq 0 ]; then
	COMMON_WT=$(dialog --backtitle "Foclabroc Toolbox" --stdout --menu "\nChoisissez une dépendance à installer :\n " 18 80 8 \
		"vcrun2008" "Visual C++ 2008" \
		"vcrun2010" "Visual C++ 2010" \
		"vcrun2012" "Visual C++ 2012" \
		"vcrun2013" "Visual C++ 2013" \
		"vcrun2022" "Visual C++ 2015 à 2022" \
		"openal" "OpenAL Runtime Creative 2023" \
		"directplay" "MS DirectPlay from DirectX" \
		"d3dx9_43" "DirectX9 (d3dx9_43)")

	if [ -n "$COMMON_WT" ]; then
		FINAL_PACKAGE=$COMMON_WT
		# Confirmation avant installation
		dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nVoulez-vous vraiment installer :\n\nLe Tricks : [$FINAL_PACKAGE]\n\nDans la Bouteille :\n\n[$selected_bottle] ?" 13 95 2>&1 >/dev/tty
		if [ $? -ne 0 ]; then
		dialog --backtitle "Foclabroc Toolbox" --infobox "\nInstallation annulée par l'utilisateur..." 5 60 2>&1 >/dev/tty
		sleep 2
		break
		fi
	fi
    else
	    dialog --backtitle "Foclabroc Toolbox" --infobox "\nChargement de la liste officiel winetricks patientez..." 5 60 2>&1 >/dev/tty
        WT_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/files/verbs/all.txt"
        TEMP_LIST=$(mktemp)
        curl -Ls "$WT_URL" -o "$TEMP_LIST"

        if [ ! -s "$TEMP_LIST" ]; then
          dialog --backtitle "Foclabroc Toolbox" --msgbox "Erreur : impossible de récupérer la liste des composants Winetricks." 8 50 2>&1 >/dev/tty
          FINAL_PACKAGE=""
        else
          PARSED_LIST=$(mktemp)
          grep -v '^=====' "$TEMP_LIST" | grep -v '^[[:space:]]*$' > "$PARSED_LIST"
          OPTIONS=()
          while IFS= read -r line; do
            pkg=$(echo "$line" | awk '{print $1}')
            desc=$(echo "$line" | cut -d' ' -f2-)
            OPTIONS+=("$pkg" "$desc")
          done < "$PARSED_LIST"
          FINAL_PACKAGE=$(dialog --backtitle "Foclabroc Toolbox" --stdout --menu "\nSélectionnez un composant Winetricks à installer :\n " 35 100 10 "${OPTIONS[@]}")
          rm -f "$TEMP_LIST" "$PARSED_LIST"
		  if [ -n "$FINAL_PACKAGE" ]; then
		    # Confirmation avant installation
		    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nVoulez-vous vraiment installer :\n\nLe Tricks : [$FINAL_PACKAGE]\n\nDans la Bouteille :\n\n[$selected_bottle] ?" 13 95 2>&1 >/dev/tty
		    if [ $? -ne 0 ]; then
			  dialog --backtitle "Foclabroc Toolbox" --infobox "\nInstallation annulée par l'utilisateur..." 5 60 2>&1 >/dev/tty
			  sleep 2
			  break
		    fi
		  fi
        fi
    fi

    # Aucune sélection effectuée
    if [ -z "$FINAL_PACKAGE" ]; then
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun composant sélectionné. Retour à la sélection de bouteille." 8 50 2>&1 >/dev/tty
      break
    fi

    # Application du Winetricks
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nRegardez l'écran principal pour suivre l'installation." 6 40 2>&1 >/dev/tty
	sleep 3
	clear
	echo 
	echo -e "\033[1;32mFOCLABROC TOOLBOX.\033[0m"
	echo -e "\033[1;32mINSTALLATION DU TRICKS [\033[1;34m$FINAL_PACKAGE\033[1;32m] EN COURS...\033[0m"
	echo -e "\033[1;32mREGARDER L'ECRAN DE BATOCERA...\033[0m"
	echo -e "\033[1;32m[NOTE : DANS DE RARE CAS CLAVIER/SOURIS PEUVENT ETRE NECESSAIRE POUR CERTAINS TRICKS.]\033[0m"
	DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 \
	-e bash -c '
		unclutter-remote -s
		batocera-wine windows tricks "'"$selected_bottle"'" "'"$FINAL_PACKAGE"'" unattended
		unclutter-remote -h
	'
	dialog --backtitle "Foclabroc Toolbox" --msgbox "\nWinetricks installé avec succès." 6 40 2>&1 >/dev/tty
	
    # Nouvelle action sur la même bouteille ?
    dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous installer un autre composant sur cette même bouteille ?" 8 50 2>&1 >/dev/tty
    [ $? -eq 0 ] || break
    clear
  done

  # Traiter une autre bouteille ?
  dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous traiter une autre bouteille Wine ?" 8 50 2>&1 >/dev/tty
  [ $? -eq 0 ] || {
    clear
    break
  }
  clear
done

# retour au menu Wine Tools
dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour au menu Wine Tools..." 5 40 2>&1 >/dev/tty
sleep 2
curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash

