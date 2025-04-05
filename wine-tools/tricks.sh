#!/bin/bash

# Boucle principale
while true; do

  # --- ÉTAPE 1 : Rechercher les dossiers .wine ---
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

  # --- ÉTAPE 2 : Sélection de la bouteille Wine ---
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

    # --- ÉTAPE 3 : Installation d'une dépendance courante VC++ ou DirectX ---
    dialog --backtitle "Foclabroc Toolbox" --yesno "Dépendances VC++ / DirectX\n\nSouhaitez-vous installer une dépendance courante comme Visual C++ ou DirectX9 ?\n\n Oui : affichage des tricks courant.\n\n Non : affichage de la liste winetricks complete.\n " 15 80 2>&1 >/dev/tty
    if [ $? -eq 0 ]; then
      COMMON_WT=$(dialog --stdout --menu "\nChoisissez une dépendance à installer :\n " 15 60 6 \
        "vcrun2008" "Visual C++ 2008" \
        "vcrun2010" "Visual C++ 2010" \
        "vcrun2012" "Visual C++ 2012" \
        "vcrun2013" "Visual C++ 2013" \
        "vcrun2022" "Visual C++ 2015 à 2022" \
        "d3dx9_43" "DirectX9 (d3dx9_43)")
      FINAL_PACKAGE=$COMMON_WT
    else
      # --- ÉTAPE 4 : Sélection d'un paquet Winetricks supplémentaire ---
      dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous installer un autre composant depuis la liste officielle de Winetricks ?" 10 60 2>&1 >/dev/tty
      if [ $? -eq 0 ]; then
        WT_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/files/verbs/all.txt"
        TEMP_LIST=$(mktemp)
        curl -sL "$WT_URL" -o "$TEMP_LIST"

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

          FINAL_PACKAGE=$(dialog --backtitle "Foclabroc Toolbox" --stdout --menu "\nSélectionnez un composant Winetricks à installer :\n " 30 85 10 "${OPTIONS[@]}")

          rm -f "$TEMP_LIST" "$PARSED_LIST"
        fi
      fi
    fi

    # --- Aucune sélection effectuée ---
    if [ -z "$FINAL_PACKAGE" ]; then
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun composant sélectionné. Retour à la sélection de bouteille." 8 50 2>&1 >/dev/tty
      break
    fi

    # --- ÉTAPE 5 : Application du Winetricks ---
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nRegardez l'écran principal pour suivre l'installation." 8 40 2>&1 >/dev/tty
	clear
    #export DISPLAY=:0.0
	DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c
    unclutter-remote -s
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nApplication de Winetricks...\n\nBouteille : $selected_bottle\n\nComposant : $FINAL_PACKAGE\n " 12 60 2>&1 >/dev/tty
clear
    DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c
    batocera-wine windows tricks "$selected_bottle" "$FINAL_PACKAGE" unattended
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nInstallation de $FINAL_PACKAGE terminée avec succès." 8 40 2>&1 >/dev/tty
    unclutter-remote -h

    # --- ÉTAPE 6 : Nouvelle action sur la même bouteille ? ---
    dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous installer un autre composant sur cette même bouteille ?" 8 50 2>&1 >/dev/tty
    [ $? -eq 0 ] || break
    clear
  done

  # --- ÉTAPE 7 : Traiter une autre bouteille ? ---
  dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous traiter une autre bouteille Wine ?" 8 50 2>&1 >/dev/tty
  [ $? -eq 0 ] || {
    clear
    break
  }
  clear
done

# --- Fin : retour au menu Wine Tools ---
dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour au menu Wine Tools..." 5 40 2>&1 >/dev/tty
sleep 2
curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash

