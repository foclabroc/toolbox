#!/bin/bash

# Get the machine hardware name
architecture=$(uname -m)

# Check if the architecture is x86_64 (AMD/Intel)
if [ "$architecture" != "x86_64" ]; then
    echo "This script only runs on AMD or Intel (x86_64) CPUs, not on $architecture."
    exit 1
fi

# Check if /userdata/system/pro does not exist and create it if necessary
if [ ! -d "/userdata/system/pro" ]; then
    mkdir -p /userdata/system/pro
fi


echo "installing foclabroc-toolbox to port folder..."
sleep 3
# Add Foclabroc-tool.sh to "ports"
curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.sh -o /userdata/roms/ports/foclabroc-tools.sh

# Add Foclabroc-tool.keys to "ports"
wget  https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.keys -P /userdata/roms/ports/

# Set execute permissions for the downloaded scripts
chmod +x /userdata/roms/ports/foclabroc-tools.sh


killall -9 emulationstation

sleep 1


echo "Finished."
