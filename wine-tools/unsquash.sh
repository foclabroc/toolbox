#!/bin/bash

#Recherche de fichiers compressé (.wtgz et .wsquashfs) dans /userdata/roms/windows
compressed_files=()
for file in /userdata/roms/windows/*.wtgz /userdata/roms/windows/*.wsquashfs; do
  [ -f "$file" ] || continue
  compressed_files+=( "$file" "" )
done

if [ ${#compressed_files[@]} -eq 0 ]; then
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nAucun fichier (.wtgz or .wsquashfs) trouvé dans /userdata/roms/windows.\nRetour au menu Wine Tools..." 12 40 2>&1 >/dev/tty
  sleep 3
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
  exit 1
fi

#Choix fichier compressé
selected_file=$(dialog --clear --title "Sélection du jeu en compressé" \
  --menu "\nSélectionnez le fichier à décompresser :\n " 25 90 4 "${compressed_files[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nAnnulé\nRetour au menu Wine Tools..." 6 40 2>&1 >/dev/tty
  sleep 2
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
  exit 1
fi

# Determiner l'extension du fichier
extension="${selected_file##*.}"

#Decompression du fichier
case "$extension" in
  wtgz)
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du fichier TGZ (wtgz)... Veuillez patienter." 6 50 2>&1 >/dev/tty
    base_name=$(basename "$selected_file" .wtgz)
    final_dir="/userdata/roms/windows/${base_name}.wine"
    rm -rf "$final_dir"
    mkdir -p "$final_dir"
	tar -xzf "$selected_file" -C "$final_dir" >/dev/tty 2>&1
    if [ $? -ne 0 ]; then
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur de décompression du .TGZ répertoire deja existant..." 6 60 2>&1 >/dev/tty
	  sleep 2
      curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/unsquash.sh | bash
    fi
    dialog --backtitle "Foclabroc Toolbox" --msgbox "Decompression effectué avec succès !\n\nEmplacement: $final_dir" 8 60 2>&1 >/dev/tty
    ;;
  wsquashfs)
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du fichier SquashFS (wsquashfs)... Veuillez patienter." 6 50 2>&1 >/dev/tty
    base_name=$(basename "$selected_file" .wsquashfs)
    final_dir="/userdata/roms/windows/${base_name}.wine"
    unsquashfs -d "$final_dir" "$selected_file" 2>&1 >/dev/tty
    if [ $? -ne 0 ]; then
      dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur de décompression du .SquashFS répertoire deja existant..." 6 70 2>&1 >/dev/tty
      sleep 2
      curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/unsquash.sh | bash
    fi
    dialog --backtitle "Foclabroc Toolbox" --msgbox "Decompression effectué avec succès !\n\nEmplacement: $final_dir" 8 60 2>&1 >/dev/tty
    ;;
  *)
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur extension de fichier non supporté..." 5 60 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/unsquash.sh | bash
    exit 1
    ;;
esac

#Suppression du fichier source (compréssé)
dialog --yesno "\nVoulez vous supprimer le fichier compressé ?\n\n($selected_file)" 9 60 2>&1 >/dev/tty
if [ $? -eq 0 ]; then
  rm -f "$selected_file"
  if [ $? -eq 0 ]; then
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nLe fichier $selected_file a été supprimé avec succès." 9 60 2>&1 >/dev/tty
  else
    dialog --backtitle "Foclabroc Toolbox" --msgbox "\nErreur lors de la suppression du fichier :\n$selected_file\nRetour au menu Wine Tools..." 10 40 2>&1 >/dev/tty
    sleep 2
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 1
  fi
fi

#Proposer de traiter un autre dossier
dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nSouhaitez-vous traiter un autre fichier compressé ?" 8 40 2>&1 >/dev/tty
if [ $? -ne 0 ]; then
  clear
  dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour au menu Wine Tools..." 5 40 2>&1 >/dev/tty
  sleep 2
  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
  exit 1
fi
clear
curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/unsquash.sh | bash
exit 1
