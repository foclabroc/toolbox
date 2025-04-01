#!/bin/bash
# Script to run Batocera Wine winetricks on a selected .wine folder.
# It scans for .wine folders in /userdata/system/wine-bottles and /userdata/roms/windows,
# then allows the user to select one trick at a time.
#
# Requirements:
#   - dialog must be installed.
#   - curl must be available for fetching the winetricks list.
#   - batocera-wine must be available.
#
# WARNING: Ensure you have backups as needed. This script executes winetricks commands via batocera-wine.

# Ensure dialog is installed.
if ! command -v dialog &> /dev/null; then
  echo "The 'dialog' command is required but not installed. Aborting."
  exit 1
fi

while true; do
  # --- STEP 1: Find all .wine folders ---
  wine_folders=()
  
  # Scan /userdata/system/wine-bottles recursively.
  while IFS= read -r folder; do
    wine_folders+=( "$folder" "" )
  done < <(find /userdata/system/wine-bottles -type d -name "*.wine")
  
  # Also scan /userdata/roms/windows for .wine folders.
  for dir in /userdata/roms/windows/*.wine; do
    [ -d "$dir" ] || continue
    wine_folders+=( "$dir" "" )
  done
  
  if [ ${#wine_folders[@]} -eq 0 ]; then
    dialog --msgbox "No .wine folders found." 10 40
    exit 1
  fi
  
  # --- STEP 2: Let the user select a wine bottle folder ---
  selected_wine=$(dialog --clear --title "Select Wine Bottle" \
    --menu "Choose a .wine folder to apply winetricks:" 15 80 6 "${wine_folders[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?
  clear
  if [ $exit_status -ne 0 ]; then
    echo "Cancelled."
    exit 1
  fi
  
  # --- Inner loop: Apply one trick at a time on the same bottle ---
  while true; do
    FINAL_PACKAGE=""
    
    # --- STEP 3: Ask for Common VC++/DirectX Dependency ---
    dialog --yesno "VC++/DirectX Dependencies\n\nDo you want to install a common VC++ runtime or DirectX9 (d3dx9_43)?\n\nThese include VC++ 2008, 2010, 2012, 2013, and 2015-2022." 12 60
    if [ $? -eq 0 ]; then
      COMMON_WT=$(dialog --stdout --radiolist "Select one common dependency to install:" 15 60 6 \
          "vcrun2008" "Visual C++ 2008" off \
          "vcrun2010" "Visual C++ 2010" off \
          "vcrun2012" "Visual C++ 2012" off \
          "vcrun2013" "Visual C++ 2013" off \
          "vcrun2022" "Visual C++ 2015-2022" off \
          "d3dx9_43" "DirectX9 (d3dx9_43)" off)
      FINAL_PACKAGE=$COMMON_WT
    else
      # --- STEP 4: Ask for Additional Winetricks Package ---
      dialog --yesno "Additional Winetricks\n\nDo you want to install an additional winetricks package (fetched from the official list)?" 12 60
      if [ $? -eq 0 ]; then
        WT_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/files/verbs/all.txt"
        WT_TEMP=$(mktemp)
        curl -sL "$WT_URL" -o "$WT_TEMP"
        if [ ! -s "$WT_TEMP" ]; then
          dialog --msgbox "Error: Failed to fetch winetricks list." 10 40
          FINAL_PACKAGE=""
        else
          WT_PARSED=$(mktemp)
          # Remove section headers and blank lines.
          grep -v '^=====' "$WT_TEMP" | grep -v '^[[:space:]]*$' > "$WT_PARSED"
          ADD_OPTIONS=()
          while IFS= read -r line; do
            # Use first word as the package name and the rest as description.
            pkg=$(echo "$line" | awk '{print $1}')
            desc=$(echo "$line" | cut -d' ' -f2-)
            ADD_OPTIONS+=("$pkg" "$desc" off)
          done < "$WT_PARSED"
          FINAL_PACKAGE=$(dialog --stdout --radiolist "Select one additional winetricks package:" 30 85 10 "${ADD_OPTIONS[@]}")
          rm -f "$WT_PARSED" "$WT_TEMP"
        fi
      fi
    fi
    
    # If no package was selected, exit the inner loop.
    if [ -z "$FINAL_PACKAGE" ]; then
      dialog --msgbox "No winetricks package selected. Returning to bottle selection." 10 40
      break
    fi
    
    # --- STEP 5: Notify and run the winetricks command in unattended mode ---
    dialog --msgbox "Check the main display for any installation prompts." 8 40
    export DISPLAY=:0.0
    unclutter-remote -s
    dialog --infobox "Running winetricks on:\n$selected_wine\n\nPackage: $FINAL_PACKAGE" 10 60
    batocera-wine windows tricks "$selected_wine" $FINAL_PACKAGE unattended
    dialog --msgbox "Winetricks processing complete." 8 40
    unclutter-remote -h
    # --- STEP 6: Ask if the user wants to apply another trick on the SAME bottle ---
    dialog --yesno "Do you want to apply another trick on the same bottle?" 8 40
    if [ $? -ne 0 ]; then
      break  # Exit inner loop to select a different bottle.
    fi
    clear
  done
  
  # --- STEP 7: Ask if the user wants to process another bottle ---
  dialog --yesno "Do you want to process another bottle?" 8 40
  if [ $? -ne 0 ]; then
    clear
    exit 0
  fi
  clear
done
echo "returning to wine tools menu"
sleep 2
curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
