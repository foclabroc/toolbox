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


echo "Installing Foclabroc-toolbox to port folder..."
sleep 3
# Add Foclabroc-tool.sh to "ports"
curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.sh -o /userdata/roms/ports/foclabroc-tools.sh

# Add Foclabroc-tool.keys to "ports"
curl -L  https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/foclabroc-tools.keys -o /userdata/roms/ports/foclabroc-tools.keys

# Set execute permissions for the downloaded scripts
chmod +x /userdata/roms/ports/foclabroc-tools.sh


killall -9 emulationstation

sleep 1


echo -e "\e[1;32mFoclabroc-Toolbox Successfully Installed in Ports folder.\e[1;37m"
sleep 3
