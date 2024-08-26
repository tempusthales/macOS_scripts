#!/bin/zsh --no-rcs
# shellcheck shell=bash
# shellcheck disable=SC2034

# Author: Tempus Thales
# Contributors:
# Date: 08/26/2024
# Version: 2024.08.26-1.0
# Description: Jamf Migration Optimization Prep

# Path to the swiftDialog binary and command file
scriptLog="/var/log/jamf_migration_prep.log"
scriptVersion="v1.0"

# Identify logged-in user
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && !/loginwindow/ { print $3 }')
USER_HOME="/Users/$loggedInUser"

# Optimize logging
function updateScriptLog() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}

# Check if script is running as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 3
fi

# Initialize log file
if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi

updateScriptLog "\n\n###\n# Jamf Migration Prep (${scriptVersion})\n###\n"
updateScriptLog "\n\n###\n# Beginning Optimization\n###\n"
updateScriptLog "Logged-in user: $loggedInUser"

# Step 1: Remove management profiles
updateScriptLog "Removing all management profiles..."
sudo profiles remove -forced -all
updateScriptLog "Management profiles removed."

# Step 2: Disable MFA on Azure account
confirm_action() {
    while true; do
        read -r -p "$1 (y/n): " yn
        case $yn in
            [Yy] ) break;;
            [Nn] ) echo "$2";;
            * ) echo "Please answer y or n.";;
        esac
    done
}

confirm_action "Please ensure that MFA is disabled on the user's Azure account or another authentication method is added. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed MFA is disabled or alternative authentication method is added."

# Step 3: Resolve any OneDrive Sync Issues
echo "Please manually resolve any OneDrive Sync issues if present."
updateScriptLog "User notified to resolve any OneDrive Sync issues."

# Step 4: Move files into OneDrive
confirm_action "Please ensure all needed files are moved into the OneDrive Folder and have synced before moving on. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed all needed files are moved into the OneDrive Folder and have synced."

# Step 5: Update/Upgrade to the most recent macOS version
echo "Updating to the latest macOS version..."
sudo softwareupdate --install --all --restart
updateScriptLog "Updating to the latest macOS version."

# Step 6: Remove OneDrive
echo "Uninstalling OneDrive..."
if [ -x /Applications/AppCleaner.app/Contents/MacOS/AppCleaner ]; then
    /Applications/AppCleaner.app/Contents/MacOS/AppCleaner --remove OneDrive
    updateScriptLog "OneDrive removed using AppCleaner."
else
    rm -rf /Applications/OneDrive.app
    updateScriptLog "OneDrive manually removed."
fi

# Step 7: Move specified applications to Trash
echo "Moving specified applications to Trash..."
apps=(
    "GarageBand" "Google Chrome" "iMovie" "Keynote" 
    "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" 
    "Microsoft PowerPoint" "Microsoft Teams" "Microsoft Word" 
    "Numbers" "Pages" "Zoom"
)

for app in "${apps[@]}"; do
    if [ -d "/Applications/$app.app" ]; then
        sudo rm -rf "/Applications/$app.app"
        updateScriptLog "$app moved to Trash."
    else
        echo "$app is not installed."
        updateScriptLog "$app was not installed, skipped removal."
    fi
done

# Empty the Trash
echo "Emptying Trash..."
rm -rf ~/.Trash/*
updateScriptLog "Trash emptied."

# Step 8: Enroll in JAMF
echo "Enrolling in JAMF..."
sudo profiles renew -type enrollment
updateScriptLog "Enrolled in JAMF."

# Run Jamf recon with the asset tag
read -r -p "Enter the computer name/asset tag: " computer_name
sudo jamf recon -assetTag "$computer_name"
updateScriptLog "Jamf recon run with asset tag: $computer_name."

# Step 9: Self Service configurations
echo "Configuring Self Service options..."
sudo jamf policy -event removeSophos -verbose
updateScriptLog "Sophos removal policy triggered."
sudo jamf policy -event makeUserPrinterAdmin -verbose
updateScriptLog "User printer admin policy triggered."
sudo jamf policy -event enableLocalLogin -verbose
updateScriptLog "Local login enabled policy triggered."

# Step 10: Install apps via Self Service
echo "Installing required apps via Self Service..."
sudo jamf policy -event installChrome -verbose
updateScriptLog "Chrome installation policy triggered."
sudo jamf policy -event installZoom -verbose
updateScriptLog "Zoom installation policy triggered."
sudo jamf policy -event installTeamViewer -verbose
updateScriptLog "TeamViewer installation policy triggered."

# Step 11: Install and Apply OneDrive Preferences/Script in Jamf Pro
echo "Applying OneDrive Preferences and Script in Jamf Pro..."
confirm_action "Please ensure OneDrive is installed and all config profiles have been scoped to the machine in JAMF Pro before moving on. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed OneDrive is installed and configured."

# Step 12: App installation verification
echo "Verifying app installation..."
updateScriptLog "App installation verification initiated."
# Manual verification or further automation can be added here

echo "Script completed. Please follow any manual steps indicated."
updateScriptLog "Script completed."