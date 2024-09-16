#!/bin/bash

# Author: Tempus Thales
# Contributors:
# Date: 09/11/2024
# Version: 2024.09.11-1.0
# Description: Installs promptForRestart.sh into /usr/local/bin

# Path to deploy the script
destination="/usr/local/bin/promptForReboot.sh"

# Check if the script already exists, if so, remove it
if [ -f "$destination" ]; then
    echo "Existing promptForReboot.sh found, removing..."
    rm "$destination"
fi

# Create the directory if it does not exist
if [ ! -d "/usr/local/bin" ]; then
    echo "/usr/local/bin not found, creating it..."
    mkdir -p /usr/local/bin
    chmod 755 /usr/local/bin
fi

# Write the promptForReboot.sh script contents to /usr/local/bin
cat << 'EOF' > "$destination"
#!/bin/bash

# Author: Tempus Thales
# Contributors: BigMacAdmin@MacAdmins, adamcodega@MacAdmins
# Date: 08/06/2024
# Version: 2024.08.06-1.0
# Description: Generates an interface for Restarting a macOS device

# Paths and marker file
scriptLog="/var/log/promptForRestart.log"
markerFile="/var/log/company/.anaconda-restart-completed"
companyLogDir="/var/log/company"
remainingTime=1440  # Initial remaining time in minutes (24 hours)
remainingTimeFile="/var/log/company/reboot_remaining_time.txt"  # File to store remaining time

# Debug parameter (set to 0 by default for production, 1 for testing)
debug=0  # Change this to 1 for testing mode (skips marker file check)

# Function to log actions
function updateScriptLog() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}

# Function to check for swiftDialog and install if missing
function dialogCheck(){
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    expectedDialogTeamID="PWA5E9TQ59"

    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
        updateScriptLog "Dialog not found. Installing..."
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
        else
            updateScriptLog "Dialog Team ID verification failed."
            exit 1
        fi
        /bin/rm -Rf "$tempDirectory"  
    else
        updateScriptLog "Dialog found. Proceeding..."
    fi
}

function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}

function loadRemainingTime() {
    if [[ -f "$remainingTimeFile" ]]; then
        remainingTime=$(cat "$remainingTimeFile")
        updateScriptLog "Loaded remaining time from file: ${remainingTime} minutes."
    else
        updateScriptLog "No remaining time file found. Defaulting to 24 hours."
    fi
}

function saveRemainingTime() {
    echo "$remainingTime" > "$remainingTimeFile"
    updateScriptLog "Saved remaining time to file: ${remainingTime} minutes."
}

function sendCannotQuitNotification() {
    /usr/local/bin/dialog 
    --title "Script Cannot Be Quit" \
    --titlefont size=22 \
    --message "You must restart your mac to complete the process. One hour has been subtracted from the countdown." \
    --messagefont size=12 \
    --button1text "OK" \
    --ontop \
    --quitkey 0 \
    --moveable \
    --width 800 \
    --height 150 \
    --icon caution \
}

function subtractOneHour() {
    shutdown -c
    remainingTime=$((remainingTime - 60))
    if ((remainingTime > 0)); then
        updateScriptLog "Subtracting 1 hour. New reboot countdown: ${remainingTime} minutes."
        shutdown -r +$((remainingTime / 60 * 60))
        saveRemainingTime
        updateScriptLog "Reboot rescheduled for ${remainingTime} minutes from now."
    else
        updateScriptLog "Time is up! Restarting now."
        shutdown -r now
    fi
}

function launchDialog() {
    while true; do
        sudo -u "$loggedInUser" /usr/local/bin/dialog \
        --title "Restart Required" \
        --titlefont size=22 \
        --message "**IMPORTANT** \n\nYour computer requires a restart. \n\nPlease save your work and restart ASAP! The system will reboot in ${remainingHours} hours if no action is taken." \
        --button1text "Restart Now" \
        --width 300 --height 400 \
        --messagefont size=16 \
        --position topright \
        --ontop \
        --moveable \
        --centericon \
        --timer $((remainingTime * 60)) \
        --icon "https://i.imgur.com/L8dgWgp.png" \
        --quitkey 0

        dialogResults=$?

        case "$dialogResults" in
            0)
                updateScriptLog "User chose to restart now."
                shutdown -c
                shutdown -r now
                break
                ;;
            4)
                updateScriptLog "Timer expired. The system will reboot as scheduled."
                break
                ;;
            10)
                updateScriptLog "Command + 0 pressed. Subtracting 1 hour and notifying user."
                subtractOneHour
                sendCannotQuitNotification
                ;;
            *)
                updateScriptLog "Unexpected exit code: ${dialogResults}. Retrying dialog."
                ;;
        esac
    done
}

trap "updateScriptLog 'Termination signal received. Subtracting one hour from countdown.'; subtractOneHour; sendCannotQuitNotification" SIGTERM SIGINT

if [[ ! -d "$companyLogDir" ]]; then
    updateScriptLog "Directory $companyLogDir does not exist. Creating it with 755 permissions."
    mkdir -p "$companyLogDir"
    chmod 755 "$companyLogDir"
    updateScriptLog "Directory $companyLogDir created and permissions set to 755."
fi

if [[ "$debug" -eq 0 ]]; then
    updateScriptLog "Running in normal mode. Checking for marker file."
    if [[ -f "${markerFile}" ]]; then
        updateScriptLog "Marker file exists. Restart has already been completed. Exiting script."
        exit 0
    fi
else
    updateScriptLog "Running in debug mode. Skipping marker file check."
fi

currentLoggedInUser
loadRemainingTime
scriptVersion="2.6"
updateScriptLog "\n\n###\n# Prompt for Reboot (${scriptVersion})\n###\n"
updateScriptLog "Starting restart prompt script."
dialogCheck
shutdown -r +$((remainingTime / 60))
updateScriptLog "Reboot scheduled in ${remainingTime} minutes."
remainingHours=$((remainingTime / 60))
launchDialog
touch "${markerFile}"
updateScriptLog "Marker file created at ${markerFile}"
updateScriptLog "SCRIPT COMPLETED."
exit 0
EOF

# Set the script to be executable
chmod +x "$destination"
echo "promptForReboot.sh deployed to $destination and made executable."

exit 0