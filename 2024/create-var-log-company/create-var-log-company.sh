#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Author: Tempus Thales
# Contributors: 
# Date: 08/22/2024
# Version: 2024.08.22-1.2
# Description: Create directory /var/log/company if it doesn't exist. For standardizing location of script logs.

# Script begins here
company="yourcompany"
scriptLog="/var/log/${company}/create-var-log-${company}.log"
scriptVersion="v1.2"

# Ensure the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Optimize logging
function updateScriptLog() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}

# Function to check and create the directory
function checkAndCreateDirectory() {
    local DIRECTORY="$1"
    
    # Check if the directory exists
    if [ -d "$DIRECTORY" ]; then
        # Directory exists, check permissions
        current_perms=$(stat -f "%Lp" "$DIRECTORY")
        if [ "$current_perms" = "755" ]; then
            updateScriptLog "Directory $DIRECTORY already exists with correct permissions (755). Exiting."
            exit 0
        else
            updateScriptLog "Directory $DIRECTORY exists but has incorrect permissions ($current_perms). Updating to 755."
            chmod 755 "$DIRECTORY"
        fi
    else
        # Directory does not exist, create it
        mkdir -p "$DIRECTORY"
        # Set secure permissions (rwxr-xr-x)
        chmod 755 "$DIRECTORY"
        updateScriptLog "Directory $DIRECTORY created with secure permissions (755)."
    fi
    
    # Verify owner and group
    chown root:root "$DIRECTORY"
    updateScriptLog "Ownership of $DIRECTORY set to root:root."
}

# Main execution
updateScriptLog "Script version $scriptVersion started."
checkAndCreateDirectory "/var/log/${company}"
updateScriptLog "Script completed successfully."