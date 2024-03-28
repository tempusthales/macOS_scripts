#!/bin/bash

# Author: Tempus Thales
# Date: 2024-03-28
# Version: 0.1
# Description: Add wallpapers to macOS Sonoma
# ShellChecking done with Grimoire GPT - https://chat.openai.com/g/g-n7Rs0IK86-grimoire


# Define the target directory path where macOS looks for custom wallpapers.
TARGET_DIR="$HOME/Library/Application Support/com.apple.desktop.photos"

# Generate a timestamp for the log file name
CURRENT_DATETIME=$(date "+%Y-%m-%d-%H%M%S")
LOG_FILE="/var/log/tesla/com.tesla.de.wallpapersetup-$CURRENT_DATETIME.log"

# Ensure the log file directory exists and create the log file
sudo mkdir -p "$(dirname "$LOG_FILE")"
if ! touch "$LOG_FILE"; then
    echo "Failed to create log file. Exiting."
    exit 2
fi

# Pre-flight Check: Client-side Script Logging Function
function updateScriptLog() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${1}" | sudo tee -a "$LOG_FILE"
}

# Start of the script execution
updateScriptLog "Script execution started."

# Ensure the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    updateScriptLog "Creating directory: $TARGET_DIR"
    if ! sudo mkdir -p "$TARGET_DIR"; then
        updateScriptLog "Failed to create target directory. Exiting."
        exit 3
    fi
else
    updateScriptLog "Directory already exists: $TARGET_DIR"
fi

# Path to the file containing base64 strings of the images
BASE64_FILE_PATH="/var/log/tesla/output/base64_output.txt"

# Check if base64 file exists
if [ ! -f "$BASE64_FILE_PATH" ]; then
    updateScriptLog "Base64 file not found at $BASE64_FILE_PATH. Exiting."
    exit 4
fi

# Read base64 strings from file into an array
BASE64_IMAGES=()
while IFS= read -r line; do
    # Skip delimiters and empty lines
    [[ "$line" == "-------"* || -z "$line" ]] && continue
    BASE64_IMAGES+=("$line")
done < "$BASE64_FILE_PATH"

# Function to generate a checksum for each image to be deployed (adapted for macOS)
function generateImageChecksum() {
    echo "$1" | base64 --decode | md5 | awk '{print $NF}'
}

# Loop through each base64 string, check against existing images
duplicateFound=0
if [ "$(ls -A $TARGET_DIR)" ]; then  # Check if directory is not empty
    for IMAGE_BASE64 in "${BASE64_IMAGES[@]}"; do
        checksum=$(generateImageChecksum "$IMAGE_BASE64")

        # Loop to generate checksums for existing images in target directory and compare
        for existingImage in "$TARGET_DIR"/*; do
            existingChecksum=$(md5 -q "$existingImage")
            if [[ "$checksum" == "$existingChecksum" ]]; then
                updateScriptLog "Duplicate image detected based on checksum comparison. Exiting."
                duplicateFound=1
                break 2 # Break out of both loops
            fi
        done
    done
fi

# Exit if duplicate images are found
if [[ $duplicateFound -eq 1 ]]; then
    exit 5
fi

# If no duplicates, proceed with deploying images
index=0
for IMAGE_BASE64 in "${BASE64_IMAGES[@]}"; do
    IMAGE_PATH="$TARGET_DIR/image_$index.jpg" # Define image path
    updateScriptLog "Decoding and saving image to $IMAGE_PATH"
    echo "$IMAGE_BASE64" | base64 --decode > "$IMAGE_PATH"
    if [ ! -s "$IMAGE_PATH" ]; then  # Check if file is not empty
        updateScriptLog "Failed to decode and save image or image is empty. Exiting."
        rm "$IMAGE_PATH"  # Remove the empty file
        exit 6
    fi
    ((index++))
done

updateScriptLog "Operation completed. You can now select the new wallpapers manually from System Preferences."

# Deploying the configuration profile at the end of the script
PROFILE_PATH="$HOME/Desktop/com.tesla.de.desktop.profile.plist"

cat > "$PROFILE_PATH" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>locked</key>
            <true/>
            <key>override-picture-path</key>
            <string>$TARGET_DIR</string>
            <key>PayloadIdentifier</key>
            <string>com.tesla.de.mydesktoppayload</string>
            <key>PayloadType</key>
            <string>com.apple.desktop</string>
            <key>PayloadUUID</key>
            <string>77a7ad50-9e32-4afb-8aee-79ae0c392848</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDisplayName</key>
    <string>Desktop</string>
    <key>PayloadIdentifier</key>
    <string>com.tesla.de.desktop.profile</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>2e00699a-8e37-417d-94b2-97b85ff722a2</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOL

updateScriptLog "Configuration profile deployed at $PROFILE_PATH."
