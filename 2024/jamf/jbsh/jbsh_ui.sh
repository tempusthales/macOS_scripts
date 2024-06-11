#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Author: Tempus Thales
# Date: 06/11/2024
# Version: 2024.06.05-2.0
# Description: Renew Management Framework via Serial Number.

#########################################################################################################
# Authentication method is using Bearer Token
#########################################################################################################

# Server connection information
URL="${4:-"https://jss.jamfcloud.com"}"

# Enter a local Jamf Pro user here
username=${5:-"username"}
password=${6:-"password"}

# Branding
icon="${7:-"https://i.imgur.com/CmyJTnq.png"}"

# Script Logging
scriptLog="${8:-"/var/log/com.yourcompany.jbsh.log"}"

# Define variables
scriptVersion="v1.0"
dialogBinary="/usr/local/bin/dialog"
dialogCommandFile="/tmp/dialog_command_file"


####################################################################################################
# JBSH dialog
####################################################################################################

# dialog Title, Message
title="Jamf Binary Self Heal Utility"
message="The Jamf Binary Self Heal utility will remotely install the Jamf Binary on computers that are unable to check-in, run policies, or update inventory."

# Construct the dialogUtility command using an array
dialogUtility=(
    --title "$title"
    --titlefont "colour=#00A4C7,weight=light,size=25"
    --message "$message"
    --messagefont "weight=medium,size=14"
    --alignment "left"
    --infotext "$scriptVersion"
    --icon "$icon"
    --iconsize '150'
    --button1text "Ok"
    --button2text "Quit"
    --button2
    --moveable
    --ontop
    --width '640'
    --height '480'
    --commandfile "$dialogCommandFile"
)

####################################################################################################
# Pre-flight Checks
####################################################################################################

# Confirm script is running as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 1
fi

####################################################################################################
# Functions - Thanks @dansnelson - https://snelson.us/2022/12/swiftdialog-izing-your-scripts/
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Jamf Binary Self-Heal Utility (${scriptVersion})\n###\n"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {
    
    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    
    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"
    
    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
        
        updateScriptLog "Dialog not found. Installing..."
        
        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        
        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
        
        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        
        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then
            
            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            updateScriptLog "swiftDialog version $(dialog --version) installed; proceeding..."
            
        else
            
            # Display a so-called "simple" dialog if Team ID fails to validate
            runAsUser osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
            quitScript "1"
            
        fi
        
        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"  
        
    else
        
        updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."
        
    fi
    
}

dialogCheck

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Function to display the dialog and capture the output
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

display_dialog() {
    dialogOutput=$(/usr/local/bin/dialog "${dialogUtility[@]}" --textfield "To use it please enter the serial number(s) of the devices you wish to re-install the Jamf Binary on.  If more than one serial please separate them with commas.  Example: serial1, serial2, serial3 etc.",editor,required)
    dialogExitCode=$?
    
    updateScriptLog "Dialog Output: $dialogOutput" # Debug statement
    echo "Dialog Output: $dialogOutput" # Debug statement
    updateScriptLog "Dialog Exit Code: $dialogExitCode" # Debug statement
    echo "Dialog Exit Code: $dialogExitCode" # Debug statement
    serialNumbers=$(echo "$dialogOutput" | sed -n 's/^.*To continue please enter the serial number(s) of the devices you wish to re-install the Jamf Binary on: //p')
    updateScriptLog "Extracted Serial Numbers: $serialNumbers"
    echo "Extracted Serial Numbers: $serialNumbers" # Debug statement
}

# Function to process a single serial number
process_serial_number() {
    local serialNumber=$1
    updateScriptLog "Processing Serial Number: $serialNumber"
    echo "Processing Serial Number: $serialNumber"

    # created base64-encoded credentials
    encodedCredentials=$( printf '%s:%s' "$username" "$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

    # generate an auth token
    authToken=$( /usr/bin/curl "$URL/api/v1/auth/token" \
    --silent \
    --request POST \
    --header "Authorization: Basic $encodedCredentials" )

    # Check if authToken contains "token"
    if [[ "$authToken" != *"token"* ]]; then
        updateScriptLog "Failed to obtain auth token"
        echo "Failed to obtain auth token"
        return
    fi

    # parse authToken for token, omit expiration
    token=$( /usr/bin/awk -F \" '/token/{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

    if [ -z "$token" ]; then
        updateScriptLog "Failed to parse auth token"
        echo "Failed to parse auth token"
        return
    fi

    # determine Jamf Pro device id
    ID=$(curl -s -H "Accept: application/xml" -H "Authorization: Bearer ${token}" "${URL}/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '/computer/general/id/text()' - 2>/dev/null)

    if [ -z "$ID" ]; then
        updateScriptLog "Failed to obtain device ID for serial number $serialNumber"
        echo "Failed to obtain device ID for serial number $serialNumber"
        return
    fi

    updateScriptLog "The JSS ID of this computer is $ID"
    echo "The JSS ID of this computer is $ID"

    # Run CURL command that reinstalls management framework
    response=$(curl --request POST \
    --url "$URL/api/v1/jamf-management-framework/redeploy/$ID" \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer $token" \
    --write-out "HTTPSTATUS:%{http_code}" \
    --silent)

    # Extract the body and status
    http_body="${response%HTTPSTATUS:*}"
    http_status="${response##*HTTPSTATUS:}"

    updateScriptLog "HTTP Body: $http_body"
    echo "HTTP Body: $http_body"
    updateScriptLog "HTTP Status: $http_status"
    echo "HTTP Status: $http_status"

    # Check the status code
    if [ "$http_status" -ne 200 ] && [ "$http_status" -ne 202 ]; then
        updateScriptLog "Error: API call failed with status $http_status"
        echo "Error: API call failed with status $http_status"
        return
    fi

    # expire the auth token
    /usr/bin/curl "$URL/uapi/auth/invalidateToken" \
    --silent \
    --request POST \
    --header "Authorization: Bearer $token"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Program Begins Here
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Main loop to show the dialog until the user quits
while true; do
    display_dialog

    # Check if Quit button was pressed
    if [ "$dialogExitCode" -eq 2 ]; then
        updateScriptLog "Quit button pressed. Exiting."
        echo "Quit button pressed. Exiting."
        exit 0
    fi

    # Check if serial numbers are empty
    if [ -z "$serialNumbers" ]; then
        updateScriptLog "No serial numbers provided"
        echo "No serial numbers provided"
        continue
    fi

    # Process each serial number
    IFS=',' read -ra serialNumberArray <<< "$serialNumbers"
    for serialNumber in "${serialNumberArray[@]}"; do
        serialNumber=$(echo "$serialNumber" | xargs) # Trim any extra whitespace
        process_serial_number "$serialNumber"
    done
done

exit 0
