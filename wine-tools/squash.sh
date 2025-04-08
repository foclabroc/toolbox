#!/bin/bash

#Recherche de dossiers .wine dans /userdata/roms/windows
wine_folders=()
for dir in /userdata/roms/windows/*.wine; do
  [ -d "$dir" ] || continue
  wine_folders+=( "$dir" "" )
done

if [ ${#wine_folders[@]} -eq 0 ]; then
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun dossier .wine trouvé dans /userdata/roms/windows.\nRetour au menu Wine Tools..." 12 40 2>&1 >/dev/tty
  sleep 2
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
  exit 1
fi

#Sélectionner le dossier .wine dans /userdata/roms/windows
selected_folder=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection du jeu en .wine" \
  --menu "\nSélectionnez le dossier .wine à compresser :\n " 30 95 4 "${wine_folders[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
  sleep 2
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
  exit 1
fi

#Compression du dossier
dialog --backtitle "Foclabroc Toolbox" --yesno "\nSouhaitez-vous compresser le dossier $selected_folder ?\n\nOptions de compression :\n- wtgz (TGZ) : Pour les petits jeux avec de nombreuses écritures.\n- wsquashfs (SquashFS) : Pour les jeux plus lourds avec peu d'écritures.\n\n(La compression convertira le dossier en une image en lecture seule avec l'extension .wtgz ou .wsquashfs.)" 15 70 2>&1 >/dev/tty
if [ $? -ne 0 ]; then
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
  exit 1
fi

compression_choice=$(dialog --backtitle "Foclabroc Toolbox" --clear --title "Sélection du type de compression" \
  --menu "\nChoisissez la méthode de compression :\n " 12 85 3 \
  "1-wtgz" "TGZ - reconditionne rapidement, idéal pour petits jeux" \
  "2-wsquashfs" "SquashFS - idéal pour gros jeux" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
  exit 1
fi

#Compression et renommage
case "$compression_choice" in
  1-wtgz)
    dialog --infobox "\nConversion du dossier au format TGZ (wtgz)... Veuillez patienter." 6 50 2>&1 >/dev/tty
    batocera-wine windows wine2winetgz "$selected_folder" 2>&1 >/dev/tty
    old_output="${selected_folder}.wtgz"
    final_output="${selected_folder%.wine}.wtgz"
    if [ -f "$old_output" ]; then
      mv "$old_output" "$final_output"
      dialog --backtitle "Foclabroc Toolbox" --msgbox "\nCompression du dossier $selected_folder en $final_output terminée !" 9 70 2>&1 >/dev/tty
    else
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur de compression : .TGZ introuvable..." 6 60 2>&1 >/dev/tty
      sleep 2
      curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
      exit 1
    fi
    ;;
  2-wsquashfs)
    dialog --infobox "\nConversion du dossier au format SquashFS (wsquashfs)... Veuillez patienter." 6 50 2>&1 >/dev/tty
    batocera-wine windows wine2squashfs "$selected_folder" 2>&1 >/dev/tty
    old_output="${selected_folder}.wsquashfs"
    final_output="${selected_folder%.wine}.wsquashfs"
    if [ -f "$old_output" ]; then
      mv "$old_output" "$final_output"
      dialog --backtitle "Foclabroc Toolbox" --msgbox "\nCompression du dossier $selected_folder en $final_output terminée !" 9 70 2>&1 >/dev/tty
    else
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur de compression : .SquashFS introuvable..." 6 60 2>&1 >/dev/tty
      sleep 2
      curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
      exit 1
    fi
    ;;
  *)
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nOption invalide sélectionnée.\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
    ;;
esac

#Proposer la suppression du dossier .wine
dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nSouhaitez-vous supprimer le dossier .wine correspondant dans /userdata/roms/windows ?\n\n(Cela supprimera le dossier :\n$selected_folder)" 11 60 2>&1 >/dev/tty
if [ $? -eq 0 ]; then
  rm -rf "$selected_folder"
  if [ $? -eq 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nLe dossier $selected_folder a été supprimé avec succès." 9 40 2>&1 >/dev/tty
  else
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nErreur lors de la suppression du dossier .wine :\n$new_path\nRetour au menu Wine Tools..." 10 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
    exit 1
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
curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
exit 1
