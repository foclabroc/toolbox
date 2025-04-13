#!/bin/bash

# Set variables
DOWNLOAD_URL="https://github.com/trashbus99/profork/releases/download/r1/Celeste64-v1.1.1-Linux-x64.zip"
DEST_DIR="/userdata/roms/ports/celeste64"
SCRIPT_PATH="/userdata/roms/ports/Celeste64.sh"
ZIP_FILE="/tmp/Celeste64.zip"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Download the file with progress bar
curl -L --progress-bar "$DOWNLOAD_URL" -o "$ZIP_FILE"

# Extract the contents to the destination directory
unzip -o "$ZIP_FILE" -d "$DEST_DIR"

# Remove the downloaded zip file
rm "$ZIP_FILE"

# Create the launch script
cat << EOF > "$SCRIPT_PATH"
#!/bin/bash
cd "$DEST_DIR"
DISPLAY=:0.0 ./Celeste64
EOF

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Inform the user
echo "Celeste64 has been added to Ports!"
echo "Please update your gamelists to see it in your menu."
sleep 8
