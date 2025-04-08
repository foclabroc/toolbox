#!/bin/bash

# Afficher la boîte de dialogue. Ajuster la hauteur et la largeur si nécessaire.
dialog --backtitle "Foclabroc Toolbox" --title "Confirmation de configuration du jeu" --yesno "\nVous devez avoir lancé le jeu en .pc au moins une fois\npour que Batocera génère la bouteille en .wine. \n\nContinuer ?" 10 60 2>&1 >/dev/tty
response=$?

# Effacer l'écran (optionnel)
clear

if [ $response -eq 0 ]; then
    echo "L'utilisateur a choisi de continuer."
else
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
fi

while true; do
  #Sélectionner le dossier .pc dans /userdata/roms/windows
  pc_folders=()
  for dir in /userdata/roms/windows/*.pc; do
    [ -d "$dir" ] || continue
    pc_folders+=( "$dir" "" )
  done

  if [ ${#pc_folders[@]} -eq 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun dossier .pc trouvé dans /userdata/roms/windows.\nRetour au menu Wine Tools..." 12 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  selected_pc=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection du jeu en .pc" \
    --menu "\nSélectionnez le dossier .pc à convertir :\n " 30 80 4 "${pc_folders[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  #Sélectionner le dossier Wine correspondant dans /userdata/system/wine-bottles
  wine_folders=()
  while IFS= read -r folder; do
    wine_folders+=( "$folder" "" )
  done < <(find /userdata/system/wine-bottles -type d -name "*.wine")

  if [ ${#wine_folders[@]} -eq 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun dossier .wine trouvé dans /userdata/system/wine-bottles.\nRetour au menu Wine Tools..." 10 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  selected_wine=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection de la bouteille Wine" \
    --menu "\nSélectionnez la bouteille wine correspondante :\n " 30 80 4 "${wine_folders[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    continue
  fi

  #Confirmer l'opération
  dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nCela copiera les données depuis :\n\n$selected_wine\n\nvers :\n\n$selected_pc\n\npuis supprimera la bouteille Wine et renommera le dossier .pc en .wine.\n\nContinuer ?" 20 60 2>&1 >/dev/tty
  if [ $? -ne 0 ]; then
	continue
  fi

  #Copier les données Wine dans le dossier .pc
  cp -a "$selected_wine"/. "$selected_pc"/
  if [ $? -ne 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur lors de la copie des données depuis la bouteille wine.\nRetour au menu Wine Tools..." 10 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  #Supprimer le dossier Wine original
  rm -rf "$selected_wine"
  if [ $? -ne 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "Erreur lors de la suppression du dossier wine :\n$selected_wine\nRetour au menu Wine Tools..." 11 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  #Renommer le dossier .pc en .wine dans /userdata/roms/windows
  base_name=$(basename "$selected_pc")
  new_name="${base_name%.pc}.wine"
  parent_dir=$(dirname "$selected_pc")
  new_path="${parent_dir}/${new_name}"

  mv "$selected_pc" "$new_path"
  if [ $? -ne 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur lors du renommage du dossier :\n$selected_pc\nen\n$new_path\nRetour au menu Wine Tools..." 11 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi

  dialog --backtitle "Foclabroc Toolbox" --msgbox "\nConversion terminée !\n\nNouveau dossier :\n\n$new_path" 15 70 2>&1 >/dev/tty

# Compression facultative du dossier
   dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous compresser le nouveau dossier .wine ?\n\nOptions de compression :\n- wtgz (TGZ) : Pour les petits jeux avec de nombreuses écritures.\n- wsquashfs (SquashFS) : Pour les jeux plus lourds avec peu d'écritures.\n\n(La compression convertira le dossier en une image en lecture seule avec l'extension .wtgz ou .wsquashfs.)" 15 70 2>&1 >/dev/tty
   if [ $? -eq 0 ]; then
     compression_choice=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection du type de compression" \
       --menu "\nChoisissez la méthode de compression :\n " 12 70 3 \
       "wtgz" "TGZ - reconditionne rapidement, idéal pour petits jeux avec écritures" \
       "wsquashfs" "SquashFS - idéal pour gros jeux avec peu d'écritures" 3>&1 1>&2 2>&3)
     exit_status=$?
     clear
     if [ $exit_status -eq 0 ]; then
       case "$compression_choice" in
         wtgz)
           dialog --backtitle "Foclabroc Toolbox" --infobox "Conversion du dossier au format TGZ (wtgz)... Veuillez patienter." 5 50 2>&1 >/dev/tty
           batocera-wine windows wine2winetgz "$new_path" 2>&1 >/dev/tty
           # Supposé que le fichier de sortie est créé sous : new_path.tgz (ex. : gamename.wine.tgz)
           old_output="${new_path}.wtgz"
           final_output="${new_path%.wine}.wtgz"
           if [ -f "$old_output" ]; then
             mv "$old_output" "$final_output"
           fi
           ;;
         wsquashfs)
           dialog --backtitle "Foclabroc Toolbox" --infobox "Conversion du dossier au format SquashFS (wsquashfs)... Veuillez patienter." 5 50 2>&1 >/dev/tty
           batocera-wine windows wine2squashfs "$new_path" 2>&1 >/dev/tty
           # Supposé que le fichier de sortie est créé sous : new_path.wsquashfs (ex. : gamename.wine.wsquashfs)
           old_output="${new_path}.wsquashfs"
           final_output="${new_path%.wine}.wsquashfs"
           if [ -f "$old_output" ]; then
             mv "$old_output" "$final_output"
           fi
           ;;
         *)
           dialog --backtitle "Foclabroc Toolbox" --msgbox "\nOption invalide sélectionnée.\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
           sleep 2
           curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
           exit 1
           ;;
       esac
       dialog --backtitle "Foclabroc Toolbox" --msgbox "\nCompression du dossier $new_name en $final_output terminée !" 8 70 2>&1 >/dev/tty

       # Vérifier si le fichier compressé existe avant de proposer la suppression du dossier .wine
       if [ -f "$final_output" ]; then
         dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nSouhaitez-vous supprimer le dossier .wine correspondant dans /userdata/roms/windows ?\n(Cela supprimera le dossier :\n$new_path)" 10 60 2>&1 >/dev/tty
         if [ $? -eq 0 ]; then
           rm -rf "$new_path"
           if [ $? -eq 0 ]; then
             dialog --backtitle "Foclabroc Toolbox" --msgbox "\nLe dossier $new_name a été supprimé avec succès." 8 40 2>&1 >/dev/tty
           else
             dialog --backtitle "Foclabroc Toolbox" --msgbox "\nErreur lors de la suppression du dossier .wine :\n$new_path\nRetour au menu Wine Tools..." 10 40 2>&1 >/dev/tty
             sleep 2
             curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
             exit 1
           fi
         fi
       fi
     fi
   fi
 
   #Proposer de traiter un autre dossier
   dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nSouhaitez-vous traiter un autre dossier ?" 8 40 2>&1 >/dev/tty
   if [ $? -ne 0 ]; then
     clear
     dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour au menu Wine Tools..." 5 40 2>&1 >/dev/tty
     sleep 2
     curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
     exit 1
   fi
   clear
   curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/pc-to-wine.sh | bash
   exit 1
 done
