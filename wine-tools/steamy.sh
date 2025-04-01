#!/bin/bash



# Create /userdata/system/wine/exe directory if it doesn't exist
mkdir -p /userdata/system/wine/exe

echo "Downloading STEAMY-AiO.exe with curl using 5 connections..."

# Function to download the file with multiple connections using curl
download_steamy_with_retry() {
    local url="$1"
    local output_dir="$2"
    local output_file="$3"
    local retries=0

    until [ $retries -ge $RETRIES ]
    do
        # Download using 5 parallel connections (mimicking aria2c functionality)
        curl -L --progress-bar --retry 3 --retry-delay 5 --retry-max-time 30 \
             --output "${output_dir}/${output_file}" "${url}" --fail --parallel --parallel-max 5
             
        if [ $? -eq 0 ]; then
            echo "Downloaded ${output_file} successfully."
            return 0
        else
            retries=$((retries+1))
            echo "Retrying... (${retries}/${RETRIES})"
        fi
    done

    echo "Failed to download ${output_file} after ${RETRIES} attempts. Exiting."
    exit 1
}

# Download STEAMY-AiO.exe to the target directory
download_steamy_with_retry "https://github.com/trashbus99/profork/releases/download/r1/STEAMY-AiO.exe" "/userdata/system/wine/exe" "STEAMY-AiO.exe"


# Check if the file was downloaded
if [ -f "/userdata/system/wine/exe/steamy.exe" ]; then
    echo "steamy.exe downloaded successfully."
else
    echo "Download failed or file not found."
fi

# Remove aria2c
rm aria2c

clear

# Output success message
echo "Steamy-AIO downloaded to /userdata/system/wine/exe."
echo ""
echo ""
echo "Rename /userdata/system/wine/exe.bak to /userdata/system/wine/exe anytime"
echo "you need to launch steamy-aio dependency installer before the windows game launches"
