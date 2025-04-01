#!/bin/bash
# Script to decompress TGZ or WSquashFS files back into .wine folders in /userdata/roms/windows.
# The script will:
#   1. Scan /userdata/roms/windows for files ending with .tgz or .wsquashfs.
#   2. Let the user select one via a dialog menu.
#   3. Determine the compression type based on the file extension.
#   4. Decompress the file:
#         - For TGZ: extract via tar and move the extracted folder.
#         - For WSquashFS: extract using unsquashfs.
#   5. Rename/move the output to have a .wine extension.
#   6. Optionally, offer to delete the compressed file.
#   7. Return to the wine tools menu.
#
# WARNING: This script will extract files and move directories. Ensure you have backups if needed.

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
  echo "The 'dialog' command is required but not installed. Aborting."
  exit 1
fi

# Check for required commands
if ! command -v tar &> /dev/null; then
  dialog --msgbox "'tar' is required but not installed. Aborting." 10 40
  exit 1
fi
if ! command -v unsquashfs &> /dev/null; then
  dialog --msgbox "'unsquashfs' is required but not installed. Aborting." 10 40
  exit 1
fi

# --- STEP 1: Find compressed files (.tgz and .wsquashfs) in /userdata/roms/windows ---
compressed_files=()
for file in /userdata/roms/windows/*.tgz /userdata/roms/windows/*.wsquashfs; do
  [ -f "$file" ] || continue
  compressed_files+=( "$file" "" )
done

if [ ${#compressed_files[@]} -eq 0 ]; then
  dialog --msgbox "No compressed files (.tgz or .wsquashfs) found in /userdata/roms/windows." 10 50
  exit 1
fi

# --- STEP 2: Let the user select a compressed file ---
selected_file=$(dialog --clear --title "Select Compressed File" \
  --menu "Choose a compressed file to decompress:" 25 90 4 "${compressed_files[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  echo "Cancelled."
  exit 1
fi

# Determine the file extension
extension="${selected_file##*.}"

# --- STEP 3: Decompress the selected file ---
case "$extension" in
  tgz)
    dialog --infobox "Decompressing TGZ file... Please wait." 5 50
    # Create temporary extraction directory
    tmp_dir=$(mktemp -d)
    tar -xzf "$selected_file" -C "$tmp_dir"
    if [ $? -ne 0 ]; then
      dialog --msgbox "Error decompressing TGZ file." 10 40
      rm -rf "$tmp_dir"
      exit 1
    fi
    # Assume the extracted folder is the first directory found in tmp_dir
    extracted_dir=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    if [ -z "$extracted_dir" ]; then
      dialog --msgbox "No directory found after decompression." 10 40
      rm -rf "$tmp_dir"
      exit 1
    fi
    # Determine final directory name: remove .tgz from filename and add .wine
    base_name=$(basename "$selected_file" .tgz)
    final_dir="/userdata/roms/windows/${base_name}.wine"
    # Move extracted directory to final destination
    mv "$extracted_dir" "$final_dir"
    if [ $? -ne 0 ]; then
      dialog --msgbox "Error moving decompressed folder to $final_dir" 10 50
      rm -rf "$tmp_dir"
      exit 1
    fi
    rm -rf "$tmp_dir"
    dialog --msgbox "Decompression complete!\nOutput: $final_dir" 10 50
    ;;
  wsquashfs)
    dialog --infobox "Decompressing WSquashFS file... Please wait." 5 50
    # Determine final directory name: remove .wsquashfs from filename and add .wine
    base_name=$(basename "$selected_file" .wsquashfs)
    final_dir="/userdata/roms/windows/${base_name}.wine"
    # Use unsquashfs to extract the image to final_dir
    unsquashfs -d "$final_dir" "$selected_file"
    if [ $? -ne 0 ]; then
      dialog --msgbox "Error decompressing WSquashFS file." 10 40
      exit 1
    fi
    dialog --msgbox "Decompression complete!\nOutput: $final_dir" 10 50
    ;;
  *)
    dialog --msgbox "Unsupported file extension: $extension" 10 40
    exit 1
    ;;
esac

# --- STEP 4: Optionally delete the compressed file ---
dialog --yesno "Do you want to delete the compressed file?\n($selected_file)" 10 60
if [ $? -eq 0 ]; then
  rm -f "$selected_file"
  if [ $? -eq 0 ]; then
    dialog --msgbox "Compressed file deleted successfully." 8 40
  else
    dialog --msgbox "Error deleting the compressed file:\n$selected_file" 10 40
  fi
fi

# --- STEP 5: Return to Wine Tools Menu ---
echo "returning to wine tools menu"
sleep 2
curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
