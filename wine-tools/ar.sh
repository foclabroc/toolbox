#!/bin/bash
# Script to help create autorun.cmd files in Batocera Wineprefixes
# This version checks if the executable is in a subfolder:
# - If yes, writes DIR=<subfolder> and CMD=<executable>
# - If not, writes only CMD=<executable>
# Also includes a loop to allow processing multiple Wineprefixes

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
  echo "The 'dialog' command is required but not installed. Aborting."
  exit 1
fi

while true; do

  # --- STEP 1: Find Wineprefix directories ---
  wineprefixes=()

  # From /userdata/roms/windows: directories ending with .pc or .wine
  for dir in /userdata/roms/windows/*; do
    if [ -d "$dir" ]; then
      if [[ "$dir" == *.pc ]] || [[ "$dir" == *.wine ]]; then
        wineprefixes+=( "$dir" )
      fi
    fi
  done

  # From /userdata/system/wine-bottles/windows: directories ending with .wine (search recursively)
  while IFS= read -r dir; do
    wineprefixes+=( "$dir" )
  done < <(find /userdata/system/wine-bottles/windows -type d -name "*.wine")

  # Check if any wineprefix was found
  if [ ${#wineprefixes[@]} -eq 0 ]; then
    dialog --msgbox "No Wineprefix directories found." 10 40
    exit 1
  fi

  # --- STEP 2: Let the user select a Wineprefix ---
  prefix_options=()
  for prefix in "${wineprefixes[@]}"; do
    # Each option: tag is the full path; description left empty
    prefix_options+=( "$prefix" "" )
  done

  selected_prefix=$(dialog --clear --title "Select Wineprefix" \
    --menu "Choose the Wineprefix where you want to create an autorun.cmd:" \
    15 80 4 "${prefix_options[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    echo "Cancelled."
    exit 1
  fi

  # --- STEP 3: Find executable files in the selected Wineprefix ---
  # Looking for .exe, .bat, and .com (case-insensitive)
  mapfile -t files < <(find "$selected_prefix" -type f \( -iname "*.exe" -o -iname "*.bat" -o -iname "*.com" \))

  if [ ${#files[@]} -eq 0 ]; then
    dialog --msgbox "No executable files found in $selected_prefix" 10 40
    # Ask if they want to do another
    continue
  fi

  # Build list with paths relative to the Wineprefix root.
  relative_files=()
  for file in "${files[@]}"; do
    # Get path relative to the selected prefix.
    rel=$(realpath --relative-to="$selected_prefix" "$file")
    relative_files+=( "$rel" "" )
  done

  selected_file=$(dialog --clear --title "Select Executable" \
    --menu "Choose the executable to run (path is relative to the Wineprefix root):" \
    15 80 4 "${relative_files[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    echo "Cancelled."
    exit 1
  fi

  # --- STEP 4: Create autorun.cmd in the Wineprefix root ---
  # Determine the directory and file name of the selected executable
  exe_dir=$(dirname "$selected_file")
  exe_file=$(basename "$selected_file")

  # If the executable file name contains spaces, wrap it in quotes for the CMD line.
  if [[ "$exe_file" == *" "* ]]; then
    exe_cmd="\"$exe_file\""
  else
    exe_cmd="$exe_file"
  fi

  autorun_file="$selected_prefix/autorun.cmd"
  {
    # Only output DIR= if the file is in a subfolder
    if [ "$exe_dir" != "." ]; then
      echo "DIR=$exe_dir"
    fi
    echo "CMD=$exe_cmd"
  } > "$autorun_file"

  dialog --msgbox "autorun.cmd created in:\n$selected_prefix" 10 40

  # --- Ask the user if they want to process another Wineprefix ---
  dialog --yesno "Do another?" 7 40
  response=$?
  clear
  if [ $response -ne 0 ]; then
    break
  fi

done

exit 0
echo "returning to wine tools menu"
sleep 2
curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
