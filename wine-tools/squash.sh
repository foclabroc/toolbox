#!/bin/bash
# Script to compress .wine folders in /userdata/roms/windows.
# The script will:
#   1. Scan /userdata/roms/windows for folders ending with .wine.
#   2. Let the user select one via a dialog menu.
#   3. Offer a compression option: TGZ (wtgz) or SquashFS (wsquashfs).
#   4. Execute the corresponding command and then rename the output file
#      to remove the .wine part (resulting in <gamename>.tgz or <gamename>.wsquashfs).
#   5. Optionally, offer to delete the corresponding .wine folder in /userdata/roms/windows.
#   6. Finally, return to the wine tools menu.
#
# WARNING: Compressed folders are read-only. Ensure you have backups if needed.

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
  echo "The 'dialog' command is required but not installed. Aborting."
  exit 1
fi

# --- STEP 1: Find .wine folders in /userdata/roms/windows ---
wine_folders=()
for dir in /userdata/roms/windows/*.wine; do
  [ -d "$dir" ] || continue
  wine_folders+=( "$dir" "" )
done

if [ ${#wine_folders[@]} -eq 0 ]; then
  dialog --msgbox "No .wine folders found in /userdata/roms/windows." 10 40
  exit 1
fi

# --- STEP 2: Let the user select a .wine folder ---
selected_folder=$(dialog --clear --title "Select .wine Folder" \
  --menu "Choose a .wine folder to compress:" 25 90 4 "${wine_folders[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  echo "Cancelled."
  exit 1
fi

# --- STEP 3: Offer Compression Options ---
dialog --yesno "Do you want to compress the selected .wine folder?\n\nCompression Options:\n- wtgz (TGZ): For small games with large writes.\n- wsquashfs (SquashFS): For larger games with small writes." 15 80
if [ $? -ne 0 ]; then
  clear
  echo "Compression cancelled."
  exit 0
fi

compression_choice=$(dialog --clear --title "Select Compression Type" \
  --menu "Choose compression method:" 12 60 2 \
  "wtgz" "TGZ - repackages quickly, best for small games with large writes" \
  "wsquashfs" "SquashFS - best for larger games with small writes" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  echo "Compression cancelled."
  exit 0
fi

# --- STEP 4: Run Compression Command and Rename Output ---
case "$compression_choice" in
  wtgz)
    dialog --infobox "Converting folder to TGZ format (wtgz)... Please wait." 5 50
    batocera-wine windows wine2winetgz "$selected_folder"
    # Expected output: <selected_folder>.tgz, e.g. gamename.wine.tgz
    old_output="${selected_folder}.tgz"
    final_output="${selected_folder%.wine}.tgz"
    if [ -f "$old_output" ]; then
      mv "$old_output" "$final_output"
      dialog --msgbox "Compression complete!\nOutput: $final_output" 8 50
    else
      dialog --msgbox "Compression failed: TGZ output not found." 10 50
    fi
    ;;
  wsquashfs)
    dialog --infobox "Converting folder to SquashFS format (wsquashfs)... Please wait." 5 50
    batocera-wine windows wine2squashfs "$selected_folder"
    # Expected output: <selected_folder>.wsquashfs, e.g. gamename.wine.wsquashfs
    old_output="${selected_folder}.wsquashfs"
    final_output="${selected_folder%.wine}.wsquashfs"
    if [ -f "$old_output" ]; then
      mv "$old_output" "$final_output"
      dialog --msgbox "Compression complete!\nOutput: $final_output" 8 50
    else
      dialog --msgbox "Compression failed: SquashFS output not found." 10 50
    fi
    ;;
  *)
    dialog --msgbox "Invalid option selected." 10 40
    ;;
esac

# --- STEP 5: Optionally Delete the Corresponding .wine Folder ---
dialog --yesno "Do you want to delete the selected .wine folder in /userdata/roms/windows?\n(This will remove the folder at:\n$selected_folder)" 10 60
if [ $? -eq 0 ]; then
  rm -rf "$selected_folder"
  if [ $? -eq 0 ]; then
    dialog --msgbox ".wine folder deleted successfully." 8 40
  else
    dialog --msgbox "Error deleting the .wine folder:\n$selected_folder" 10 40
  fi
fi

# --- STEP 6: Return to Wine Tools Menu ---
echo "returning to wine tools menu"
sleep 2
curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
