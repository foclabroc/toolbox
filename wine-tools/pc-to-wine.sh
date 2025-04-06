#!/bin/bash

# Display the dialog box. Adjust height and width as needed.
dialog --title "Game Setup Confirmation" --yesno "You must run the windows game in a .pc folder at least once for Batocera to generate a wine bottle/.wine folder for the game.  Continue?" 10 60

# Capture the exit status of the dialog command.
# Exit status 0 means the user pressed "Yes", and 1 means "No".
response=$?

# Clear the screen (optional)
clear

if [ $response -eq 0 ]; then
    echo "User chose to continue."
    # Continue with your script logic here.
else
    echo "User chose to exit."
    exit 1
fi

while true; do
  # --- STEP 1: Select the .pc folder from /userdata/roms/windows ---
  pc_folders=()
  for dir in /userdata/roms/windows/*.pc; do
    [ -d "$dir" ] || continue
    pc_folders+=( "$dir" "" )
  done

  if [ ${#pc_folders[@]} -eq 0 ]; then
    dialog --msgbox "No .pc folders found in /userdata/roms/windows." 10 40
    exit 1
  fi

  selected_pc=$(dialog --clear --title ".pc Folder Selection" \
    --menu "Select the .pc folder to convert:" 15 80 4 "${pc_folders[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    echo "Cancelled."
    exit 1
  fi

  # --- STEP 2: Select the corresponding Wine Bottle folder from /userdata/system/wine-bottles ---
  wine_folders=()
  while IFS= read -r folder; do
    wine_folders+=( "$folder" "" )
  done < <(find /userdata/system/wine-bottles -type d -name "*.wine")

  if [ ${#wine_folders[@]} -eq 0 ]; then
    dialog --msgbox "No .wine folders found in /userdata/system/wine-bottles." 10 40
    exit 1
  fi

  selected_wine=$(dialog --clear --title "Wine Bottle Selection" \
    --menu "Select the corresponding wine bottle folder:" 15 80 4 "${wine_folders[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    echo "Cancelled."
    exit 1
  fi

  # --- STEP 3: Confirm operation ---
  dialog --yesno "This will copy data from:\n$selected_wine\ninto:\n$selected_pc\nthen delete the wine bottle and rename the .pc folder to .wine.\nProceed?" 12 60
  if [ $? -ne 0 ]; then
    clear
    echo "Operation cancelled."
    exit 1
  fi

  # --- STEP 4: Copy Wine Bottle Data into the .pc folder ---
  cp -a "$selected_wine"/. "$selected_pc"/
  if [ $? -ne 0 ]; then
    dialog --msgbox "Error copying data from wine bottle." 10 40
    exit 1
  fi

  # --- STEP 5: Delete the original Wine Bottle folder ---
  rm -rf "$selected_wine"
  if [ $? -ne 0 ]; then
    dialog --msgbox "Error deleting the wine bottle folder:\n$selected_wine" 10 40
    exit 1
  fi

  # --- STEP 6: Rename the .pc folder to .wine in /userdata/roms/windows ---
  base_name=$(basename "$selected_pc")
  new_name="${base_name%.pc}.wine"
  parent_dir=$(dirname "$selected_pc")
  new_path="${parent_dir}/${new_name}"

  mv "$selected_pc" "$new_path"
  if [ $? -ne 0 ]; then
    dialog --msgbox "Error renaming folder:\n$selected_pc\nto\n$new_path" 10 40
    exit 1
  fi

  dialog --msgbox "Conversion complete!\nNew folder:\n$new_path" 10 40

  # --- STEP 7: Optional Folder Compression ---
  dialog --yesno "Do you want to compress the new .wine folder?\n\nCompression Options:\n- wtgz (TGZ): For small games with large writes.\n- wsquashfs (SquashFS): For larger games with small writes.\n\n(Compression will convert the folder into a read-only image with extension .wtgz or .wsquashfs.)" 15 70
  if [ $? -eq 0 ]; then
    compression_choice=$(dialog --clear --title "Select Compression Type" \
      --menu "Choose compression method:" 12 60 2 \
      "wtgz" "TGZ - repackages quickly, best for small games with large writes" \
      "wsquashfs" "SquashFS - best for larger games with small writes" 3>&1 1>&2 2>&3)
    exit_status=$?
    clear
    if [ $exit_status -eq 0 ]; then
      case "$compression_choice" in
        wtgz)
          dialog --infobox "Converting folder to TGZ format (wtgz)... Please wait." 5 50
          batocera-wine windows wine2winetgz "$new_path"
          # Assume the output file is created as: new_path.tgz (e.g., gamename.wine.tgz)
          old_output="${new_path}.tgz"
          final_output="${new_path%.wine}.tgz"
          if [ -f "$old_output" ]; then
            mv "$old_output" "$final_output"
          fi
          ;;
        wsquashfs)
          dialog --infobox "Converting folder to SquashFS format (wsquashfs)... Please wait." 5 50
          batocera-wine windows wine2squashfs "$new_path"
          # Assume the output file is created as: new_path.wsquashfs (e.g., gamename.wine.wsquashfs)
          old_output="${new_path}.wsquashfs"
          final_output="${new_path%.wine}.wsquashfs"
          if [ -f "$old_output" ]; then
            mv "$old_output" "$final_output"
          fi
          ;;
        *)
          dialog --msgbox "Invalid option selected." 10 40
          ;;
      esac
      dialog --msgbox "Folder compression complete!" 8 40
    fi
  fi

  # --- STEP 8: Optionally Delete the Corresponding .wine Folder in /userdata/roms/windows ---
  dialog --yesno "Do you want to delete the corresponding .wine folder in /userdata/roms/windows?\n(This will remove the folder at:\n$new_path)" 10 60
  if [ $? -eq 0 ]; then
    rm -rf "$new_path"
    if [ $? -eq 0 ]; then
      dialog --msgbox ".wine folder deleted successfully." 8 40
    else
      dialog --msgbox "Error deleting the .wine folder:\n$new_path" 10 40
    fi
  fi

  # --- STEP 9: Offer to process another folder ---
  dialog --yesno "Do you want to process another folder?" 8 40
  if [ $? -ne 0 ]; then
    clear
    exit 0
  fi
  clear
  echo "returning to wine tools menu"
  sleep 2
  curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
done
