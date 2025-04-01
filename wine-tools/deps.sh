#!/bin/bash
# Script to clean, create, and download common wine executables for Batocera.
# It deletes the existing /userdata/system/wine/exe and /userdata/system/wine/exe.bak folders,
# creates a fresh /userdata/system/wine/exe folder, and then offers a checklist
# of common wine executables to download.
#
# The following items can be downloaded:
#   - DirectX3D package (7z archive) which is extracted afterwards.
#   - Various Visual C++ Redistributables (multiple years and architectures).
#   - An option to download the full Steamy-AIO Wine dependency.
#
# These executables (or installers) will run on the next game launch.
#
# Requirements:
#   - dialog, wget, 7zr, and curl must be installed.
#
# WARNING: This script deletes existing folders. Ensure you have backups if needed.

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
  echo "The 'dialog' command is required but not installed. Aborting."
  exit 1
fi

# --- STEP 1: Remove old directories and create fresh /userdata/system/wine/exe ---
rm -rf /userdata/system/wine/exe /userdata/system/wine/exe.bak
mkdir -p /userdata/system/wine/exe

# --- STEP 2: Present the download options via dialog checklist ---
options=( 
  "directx" "DirectX3D (7z package)" off

  "vcredist_1519_x86" "VC++ 2015-2019 (x86)" off
  "vcredist_1519_x64" "VC++ 2015-2019 (x64)" off

  "vcredist_2019_x86" "VC++ 2019 (x86)" off
  "vcredist_2019_x64" "VC++ 2019 (x64)" off

  "vcredist_2017_x86" "VC++ 2017 (x86)" off
  "vcredist_2017_x64" "VC++ 2017 (x64)" off

  "vcredist_2015_x86" "VC++ 2015 (x86)" off
  "vcredist_2015_x64" "VC++ 2015 (x64)" off

  "vcredist_2013_x86" "VC++ 2013 (x86)" off
  "vcredist_2013_x64" "VC++ 2013 (x64)" off

  "vcredist_2012_x86" "VC++ 2012 (x86)" off
  "vcredist_2012_x64" "VC++ 2012 (x64)" off

  "vcredist_2010_x86" "VC++ 2010 (x86)" off
  "vcredist_2010_x64" "VC++ 2010 (x64)" off

  "vcredist_2008_x86" "VC++ 2008 (x86)" off
  "vcredist_2008_x64" "VC++ 2008 (x64)" off

  "vcredist_2005_x86" "VC++ 2005 (x86)" off
  "vcredist_2005_x64" "VC++ 2005 (x64)" off

  "steamy" "Steamy-AIO Wine dependency" off
)

selected=$(dialog --stdout --checklist "Download Wine Executables\n\nSelect the executables to download.\nThese dependency installers will run the next time you start the game." 30 85 14 "${options[@]}")
exit_status=$?
clear
if [ $exit_status -ne 0 ]; then
  echo "Operation cancelled."
  exit 1
fi

# --- STEP 3: Process the selected options ---
# The selected variable is a space-separated list of tags.
for tag in $selected; do
  case "$tag" in
    "directx")
      dialog --infobox "Downloading DirectX3D package..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/directx.7z
      if [ -f /userdata/system/wine/exe/directx.7z ]; then
        7zr x /userdata/system/wine/exe/directx.7z -o/userdata/system/wine/exe
        rm /userdata/system/wine/exe/directx.7z
      fi
      ;;
    "vcredist_1519_x86")
      dialog --infobox "Downloading VC++ 2015-2019 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2015_2019.exe
      ;;
    "vcredist_1519_x64")
      dialog --infobox "Downloading VC++ 2015-2019 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2015_2019.exe
      ;;
    "vcredist_2019_x86")
      dialog --infobox "Downloading VC++ 2019 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2019.exe
      ;;
    "vcredist_2019_x64")
      dialog --infobox "Downloading VC++ 2019 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2019.exe
      ;;
    "vcredist_2017_x86")
      dialog --infobox "Downloading VC++ 2017 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2017.exe
      ;;
    "vcredist_2017_x64")
      dialog --infobox "Downloading VC++ 2017 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2017.exe
      ;;
    "vcredist_2015_x86")
      dialog --infobox "Downloading VC++ 2015 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2015.exe
      ;;
    "vcredist_2015_x64")
      dialog --infobox "Downloading VC++ 2015 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2015.exe
      ;;
    "vcredist_2013_x86")
      dialog --infobox "Downloading VC++ 2013 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2013.exe
      ;;
    "vcredist_2013_x64")
      dialog --infobox "Downloading VC++ 2013 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2013.exe
      ;;
    "vcredist_2012_x86")
      dialog --infobox "Downloading VC++ 2012 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2012.exe
      ;;
    "vcredist_2012_x64")
      dialog --infobox "Downloading VC++ 2012 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2012.exe
      ;;
    "vcredist_2010_x86")
      dialog --infobox "Downloading VC++ 2010 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2010.exe
      ;;
    "vcredist_2010_x64")
      dialog --infobox "Downloading VC++ 2010 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2010.exe
      ;;
    "vcredist_2008_x86")
      dialog --infobox "Downloading VC++ 2008 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2008.exe
      ;;
    "vcredist_2008_x64")
      dialog --infobox "Downloading VC++ 2008 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2008.exe
      ;;
    "vcredist_2005_x86")
      dialog --infobox "Downloading VC++ 2005 (x86)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x86_2005.exe
      ;;
    "vcredist_2005_x64")
      dialog --infobox "Downloading VC++ 2005 (x64)..." 4 50
      wget -P /userdata/system/wine/exe https://batocera.org/users/liberodark/wine/vcredist_x64_2005.exe
      ;;
    "steamy")
      dialog --infobox "Downloading Steamy-AIO Wine dependency..." 4 50
      curl -Ls https://github.com/trashbus99/profork/raw/master/wine-custom/steamy.sh | bash
      ;;
    *)
      dialog --msgbox "Unknown option: $tag" 10 40
      ;;
  esac
done

dialog --msgbox "Downloads complete. The selected dependency launchers will run the next time you start the game." 10 50
clear
exit 0
echo "returning to wine tools menu"
sleep 2
curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
