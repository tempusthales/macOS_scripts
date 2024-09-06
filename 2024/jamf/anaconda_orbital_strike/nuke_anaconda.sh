#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Author: Tempus Thales
# Contributors: Tron LLM
# Date: 06/20/2024
# Description: Anaconda Removal Tool

# Path to the swiftDialog binary and command file
dialogBinary="/usr/local/bin/dialog"
dialogCommandFile="/tmp/dialog_command_file"
scriptLog="/var/log/anaconda_orbital_strike.log"
scriptVersion="v1.0"
icon="${4:-"https://i.imgur.com/CmyJTnq.png"}"

# Dialog Title and Message
title="Anaconda Orbital Strike"
message="\n\nThis tool will remove **Anaconda** and all its components from macOS. **Anaconda** is a licensed framework that is not vetted or authorized to run anywhere unless its licensed.  \n\n### There is nothing for you to do at this point, the removal has been automated by Skynet."

# Dialog Utility Array
dialogUtility=(
    --title "$title"
    --titlefont "colour=#00A4C7,weight=light,size=25"
    --message "$message"
    --messagefont "weight=medium,size=14"
    --alignment "left"
    --infotext "$scriptVersion"
    --icon "$icon"
    --iconsize '150'
    --moveable
    --mini
    --ontop
    --width '800'
    --height '550'
    --commandfile "$dialogCommandFile"
)

####################################################################################################
# Functions
####################################################################################################
# Thanks @dansnelson - https://snelson.us/2022/12/swiftdialog-izing-your-scripts/

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi

updateScriptLog "\n\n###\n# Orbital Strike OS (${scriptVersion})\n###\n"
updateScriptLog "\n\n###\n# Beginning Anaconda Orbital Strike\n###\n"

####################################################################################################
# dialogCheck function by the awesome acodega@macadmins Slack
# https://github.com/acodega/dialog-scripts/blob/main/dialogCheckFunction.sh

function dialogCheck() {
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    expectedDialogTeamID="PWA5E9TQ59"

    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
        updateScriptLog "Dialog not found. Installing..."
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then
            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            updateScriptLog "swiftDialog version $(dialog --version) installed; proceeding..."
        else
            runAsUser osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
            exit 2
        fi

        /bin/rm -Rf "$tempDirectory"
    else
        updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."
    fi
}

dialogCheck

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 3
fi

update_dialog() {
    local step=$1
    local progress=$2
    echo -e "progress: $progress\nmessage: $step" >> "$dialogCommandFile"
}

"${dialogBinary}" "${dialogUtility[@]}" --progress &

progress=0

update_dialog "Checking for Anaconda installation..." $progress
updateScriptLog "Checking for Anaconda installation..."

check_anaconda() {
    if command -v conda &> /dev/null; then
        return 0
    else
        return 1
    fi
}

if ! check_anaconda; then
    update_dialog "Anaconda is not installed." 100
    updateScriptLog "Anaconda is not installed."
    updateScriptLog "\n\n###\n# Orbital Strike Aborted. Nothing to Nuke. (╯°︵°)╯ \n###\n"
    sleep 1
    exit 4
fi

# Check if Anaconda Navigator is running and kill the process if it is
navigator_pid=$(pgrep -f "Anaconda-Navigator")
if [[ -n "$navigator_pid" ]]; then
    update_dialog "Anaconda Navigator is running. Stopping process..." $progress
    updateScriptLog "Anaconda Navigator is running. Stopping process..."
    if ! kill -9 "$navigator_pid"; then
        update_dialog "Failed to stop Anaconda Navigator." 100
        updateScriptLog "Failed to stop Anaconda Navigator."
        exit 5
    fi
    progress=$((progress + 10))
    update_dialog "Anaconda Navigator stopped." $progress
    updateScriptLog "Anaconda Navigator stopped."
fi

progress=$((progress + 10))
update_dialog "Anaconda installation found. Proceeding with removal..." $progress
updateScriptLog "Anaconda installation found. Proceeding with removal...(╯°□°)╯︵ ┻━┻ "

update_dialog "Installing anaconda-clean..." $progress
updateScriptLog "Installing anaconda-clean..."
if ! conda install anaconda-clean -y; then
    update_dialog "Failed to install anaconda-clean." 100
    updateScriptLog "Failed to install anaconda-clean."
    exit 6
fi

progress=$((progress + 10))
update_dialog "Running anaconda-clean..." $progress
updateScriptLog "Running anaconda-clean..."
if ! anaconda-clean --yes; then
    update_dialog "anaconda-clean failed." 100
    updateScriptLog "anaconda-clean failed."
    exit 7
fi

update_dialog "Removing anaconda-clean backup..." $progress
updateScriptLog "Removing anaconda-clean backup..."
if [ -d "$HOME/.anaconda_backup" ]; then
    if ! rm -rf "$HOME/.anaconda_backup"; then
        update_dialog "Failed to remove anaconda-clean backup." 100
        updateScriptLog "Failed to remove anaconda-clean backup."
        exit 8
    fi
fi

remove_directory() {
    dir=$1
    if [ -d "$dir" ]; then
        update_dialog "Removing $dir..." $progress
        updateScriptLog "Removing $dir..."
        if ! rm -rf "$dir"; then
            update_dialog "Failed to remove $dir." 100
            updateScriptLog "Failed to remove $dir."
            exit 9
        fi
    else
        update_dialog "$dir not found." $progress
        updateScriptLog "$dir not found."
    fi
}

remove_directory "$HOME/anaconda3"
progress=$((progress + 10))
remove_directory "/opt/anaconda3"
progress=$((progress + 10))
remove_directory "$HOME/anaconda2"
progress=$((progress + 10))
remove_directory "/opt/anaconda2"
progress=$((progress + 10))

# Enhanced check and logging for /Applications/Anaconda-Navigator.app
if [ -d "/Applications/Anaconda-Navigator.app" ]; then
    update_dialog "Removing /Applications/Anaconda-Navigator.app..." $progress
    rm -rf "/Applications/Anaconda-Navigator.app"
    updateScriptLog "Removing /Applications/Anaconda-Navigator.app..."
    if ! rm -rf "/Applications/Anaconda-Navigator.app"; then
        update_dialog "Failed to remove /Applications/Anaconda-Navigator.app." 100
        updateScriptLog "Failed to remove /Applications/Anaconda-Navigator.app."
        exit 9
    fi
    update_dialog "/Applications/Anaconda-Navigator.app removed successfully." $progress
    updateScriptLog "/Applications/Anaconda-Navigator.app removed successfully."
else
    update_dialog "/Applications/Anaconda-Navigator.app not found." $progress
    updateScriptLog "/Applications/Anaconda-Navigator.app not found."
fi

progress=$((progress + 10))

update_dialog "Removing .condarc..." $progress
updateScriptLog "Removing .condarc..."
if [ -f "$HOME/.condarc" ]; then
    if ! rm "$HOME/.condarc"; then
        update_dialog "Failed to remove .condarc." 100
        updateScriptLog "Failed to remove .condarc."
        exit 10
    fi
fi

update_dialog "Removing .conda directory..." $progress
updateScriptLog "Removing .conda directory..."
if [ -d "$HOME/.conda" ]; then
    if ! rm -rf "$HOME/.conda"; then
        update_dialog "Failed to remove .conda directory." 100
        updateScriptLog "Failed to remove .conda directory."
        exit 11
    fi
fi

update_dialog "Removing .continuum directory..." $progress
updateScriptLog "Removing .continuum directory..."
if [ -d "$HOME/.continuum" ]; then
    if ! rm -rf "$HOME/.continuum"; then
        update_dialog "Failed to remove .continuum directory." 100
        updateScriptLog "Failed to remove .continuum directory."
        exit 12
    fi
fi

remove_path() {
    file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        if ! sed -i '' "/# added by Anaconda[23] installer/d" "$file"; then
            update_dialog "Failed to clean $file." 100
            updateScriptLog "Failed to clean $file."
            exit 13
        fi
        if ! sed -i '' "/export PATH=\".*\/anaconda[23]\/bin:\$PATH\"/d" "$file"; then
            update_dialog "Failed to clean $file." 100
            updateScriptLog "Failed to clean $file."
            exit 13
        fi
        if ! sed -i '' "/export PATH=\"\/Users\/.*\/anaconda[23]\/bin:\$PATH\"/d" "$file"; then
            update_dialog "Failed to clean $file." 100
            updateScriptLog "Failed to clean $file."
            exit 13
        fi
        update_dialog "Cleaned $file" $progress
        updateScriptLog "Cleaned $file"
    fi
}

remove_path "$HOME/.bash_profile"
remove_path "$HOME/.bashrc"
remove_path "$HOME/.zshrc"

update_dialog "Anaconda removal completed successfully." 100
updateScriptLog "Anaconda removal completed successfully."
updateScriptLog "\n\n###\n#Orbital Strike Concluded\n###\n ┬─┬ノ( º _ ºノ)"

sleep 1

touch /var/log/flynn.lives

exit 0

####################################################################################################
# Exit Codes
# 0 - Success
# 2 - Dialog Team ID verification failed
# 3 - Script must be run as root
# 4 - Anaconda is not installed
# 5 - Failed to stop Anaconda Navigator
# 6 - Failed to install anaconda-clean
# 7 - anaconda-clean failed
# 8 - Failed to remove anaconda-clean backup
# 9 - Failed to remove Anaconda directory
# 10 - Failed to remove .condarc
# 11 - Failed to remove .conda directory
# 12 - Failed to remove .continuum directory
# 13 - Failed to clean shell configuration file
####################################################################################################