#!/bin/bash

# Author: Tempus Thales
# Date: 2024-03-28
# Version: 0.1
# Description: Convert images to base64 and log the operation.
# ShellChecking done with Grimoire GPT - https://chat.openai.com/g/g-n7Rs0IK86-grimoire

# Specify the directory containing the images
IMAGE_DIR="/PATH/TO/WALLPAPER/LOCATION"

# Image file extension you want to convert
IMAGE_EXTENSION="jpg"

# Output directory for base64 output
OUTPUT_DIR="/var/log/company/output"
OUTPUT_FILE="$OUTPUT_DIR/base64_output.txt"

# Log directory
LOG_DIR="/var/log/company"
scriptLog="$LOG_DIR/wallpapersetup-$(date "+%Y-%m-%d-%H:%M").log"

# Ensure the output and log directories exist, create if not
for dir in "$OUTPUT_DIR" "$LOG_DIR"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || { echo "Failed to create $dir. Ensure you have the necessary permissions."; exit 1; }
    fi
done

# Pre-flight Check: Ensure the log file exists
if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}" || { echo "Failed to create $scriptLog. Ensure you have the necessary permissions."; exit 2; }
fi

# Function to update the script log
function updateScriptLog() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}

# Log the start of the script execution
updateScriptLog "Script execution started."

# Check for files with the specified extension
FILES_EXIST=$(find "$IMAGE_DIR" -type f -name "*.$IMAGE_EXTENSION" | wc -l)
if [ "$FILES_EXIST" -eq 0 ]; then
    updateScriptLog "No files found with the .$IMAGE_EXTENSION extension."
    exit 3 # No files found
fi

# Start conversion process
updateScriptLog "Starting conversion of images to base64."

# Loop through each image in the directory and convert it to base64
for IMAGE_PATH in "$IMAGE_DIR"/*.$IMAGE_EXTENSION; do
    if [ -f "$IMAGE_PATH" ]; then
        FILE_NAME=$(basename "$IMAGE_PATH")
        updateScriptLog "Converting $IMAGE_PATH to base64."

        # Start delimiter for base64 data
        echo "------- Start of $FILE_NAME -------" >> "$OUTPUT_FILE"
        
        # Convert image to base64 and append to the output file
        base64 -i "$IMAGE_PATH" >> "$OUTPUT_FILE" || { updateScriptLog "Failed to convert $IMAGE_PATH"; exit 4; }
        
        # End delimiter for base64 data
        echo "------- End of $FILE_NAME -------" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE" # Adds extra newline for readability
    else
        updateScriptLog "$IMAGE_PATH is not a file, skipping..."
        continue
    fi
done

# Log script completion
updateScriptLog "Operation completed. Base64 strings saved to $OUTPUT_FILE."
exit 0 # Success

# Exit Codes:
# 0 - Success
# 1 - Failed to create output/log directory
# 2 - Failed to create log file
# 3 - No files found with the specified extension
# 4 - Failed to convert an image to base64
