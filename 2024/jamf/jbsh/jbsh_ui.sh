#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Author: Tempus Thales
# Contributors:
# - MacAdmins Community: @bartreardon, @HowieIsaacks, @BigMacAdmin, @adamcodega @cocopuff2u
# - Ellie Romero ~ Jamf
# Date: 06/11/2024
# Version: 2024.07.15-2.0
# Description: Renew Management Framework via Serial Number.
#
# Support: Support is limited, but if you need help find @gil in MacAdmins Slack. You can join here: https://macadmins.org

#########################################################################################################
# Authentication method is using Bearer Token
#########################################################################################################
# API Settings Needed
#
# API ROLE
# Role Name: jbsh_role
# Privileges: Read Computer Check-in, Read Computers, Send Computer Remote Command to Install Package
#
# API Client
# API Display Name: jbsh client
# API Role: jbsh_role
# Access Token Lifetime: 60
# Enable API Client
# ** Copy the Client ID and Client Secret into the fields below **
#########################################################################################################

# Server connection information
# Change this to your value
URL="${4:-"https://yourjss.jamfcloud.com"}"

# Enter the Jamf Pro API client info here
API_Client_ID=${5:-"apiclientid"}
Client_Secret=${6:-"clientsecret"}

# Branding image
icon="${7:-"https://i.imgur.com/CmyJTnq.png"}"

# Script Logging
# Change this to your value
scriptLog="${8:-"/var/log/com.yourcompany.jbsh.log"}"

# Define variables
scriptVersion="v2.0"
dialogBinary="/usr/local/bin/dialog"
dialogCommandFile="/tmp/dialog_command_file"

# Array to hold failed and successful serial numbers
failed_serial_numbers=()
successful_serial_numbers=()

####################################################################################################
# JBSH dialog
####################################################################################################

# dialog Title, Message
title="Jamf Binary Self Heal Utility"
message="\n\nThe **Jamf Binary Self Heal** utility will remotely install the Jamf Binary on computers that are unable to check-in, run policies, or update inventory.  \n\n### Instructions\n\nTo use it please enter the serial number(s) of the devices you wish to re-install the Jamf Binary on.  \n* For single serials just enter it and press OK.\n* For more than one serial please separate with commas:"
textField="Example: serial1, serial2, serial3, etc."
infoBox="### Advanced Support\n\nIf the utility fails, open Terminal.app in the affected device: \n- \`sudo jamf removeFramework\`\n- \`sudo profiles renew -type enrollment\`\n- \`sudo jamf policy\`\n\n#### MacAdmins Link:\n- [https://macadmins.org](https://macadmins.org/)"
dialogUtility=(
    --title "$title"
    --titlefont "colour=#00A4C7,weight=light,size=25"
    --message "$message"
    --messagefont "weight=medium,size=14"
    --textfield "$textField",editor,required
    --alignment "left"
    --infotext "$scriptVersion"
    --icon "$icon"
    --infobox "$infoBox"
    --displaylog
    --iconsize '150'
    --button1text "Ok"
    --button2text "Quit"
    --button2
    --moveable
    --ontop
    --width '800'
    --height '550'
    --commandfile "$dialogCommandFile"
)

# Function to display a dialog with both successful and failed serial numbers
function show_summary_dialog() {
    failed_serial_list=$(printf "%s, " "${failed_serial_numbers[@]}")
    failed_serial_list=${failed_serial_list%, }
    
    successful_serial_list=$(printf "%s, " "${successful_serial_numbers[@]}")
    successful_serial_list=${successful_serial_list%, }
    
    # Construct the message
    message="### Summary\n\n"
    if [ ${#successful_serial_numbers[@]} -ne 0 ]; then
        message+="The following serial numbers were successfully processed:\n\n$successful_serial_list\n\n"
    fi
    if [ ${#failed_serial_numbers[@]} -ne 0 ]; then
        message+="The following serial numbers failed to process:\n\n$failed_serial_list\n\n"
    fi

    message+="Would you like to quit or restart the application?"

    /usr/local/bin/dialog --title "Process Summary" \
    --message "$message" \
    --button1text "Restart" \
    --button2text "Quit" \
    --button1 \
    --button2 \
    --icon "$icon" \
    --moveable \
    --ontop \
    --width '800' \
    --height '550' \
    --commandfile "$dialogCommandFile"
    
    return $?
}


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
    
    # Get the current version of swiftDialog from GitHub
    dialogURL=$(curl -s https://api.github.com/repos/swiftdialog/swiftdialog/releases/latest | \
        awk -F'"' '/browser_download_url/ {print $4}')
    
    updateScriptLog "Downloading Dialog from URL: $dialogURL"
    
    if [[ ! -x "${dialogBinary}" ]]; then
        
        updateScriptLog "SwiftDialog not found; installing..."
        
        tempDirectory=$(mktemp -d)
        
        curl -sL "$dialogURL" -o "${tempDirectory}/Dialog.pkg"
        
        # Check if installation package is valid
        teamID=$(pkgutil --pkg-info com.swiftdialog.dialog | awk -F' ' '/origin=/ {print $NF}')
        
        if [ "$teamID" != "$expectedDialogTeamID" ]; then
            
            updateScriptLog "Downloaded Dialog package is not from the expected Team ID. Exiting."
            
            /usr/local/bin/dialog --title "Setup Your Mac: Error" \
            --message "The Dialog installer package is not from the expected Team ID. Exiting the script." \
            --button1text "Close" \
            --button1 \
            --icon caution
            
            exit 1
        fi
        
        # Install the Dialog package
        /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
        
        # Check if installation succeeded
        if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
            updateScriptLog "Dialog installation failed."
            
            /usr/local/bin/dialog --title "Setup Your Mac: Error" \
            --message "The Dialog installation failed. Please contact your administrator." \
            --button1text "Close" \
            --button1 \
            --icon caution
            
            exit 1
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

function display_dialog() {
    dialogOutput=$(/usr/local/bin/dialog "${dialogUtility[@]}")
    dialogExitCode=$?
    updateScriptLog "Dialog Output: $dialogOutput" # Debug statement
    echo "Dialog Output: $dialogOutput" # Debug statement
    updateScriptLog "Dialog Exit Code: $dialogExitCode" # Debug statement
    echo "Dialog Exit Code: $dialogExitCode" # Debug statement
    serialNumbers=$(echo "$dialogOutput" | sed -n 's/^.*Example: serial1, serial2, serial3, etc. : //p')
    echo "$serialNumbers"
    updateScriptLog "Extracted Serial Numbers: $serialNumbers"
    echo "Extracted Serial Numbers: $serialNumbers" # Debug statement
}

# Function to process a single serial number
function process_serial_number() {
    local serialNumber=$1
    updateScriptLog "Processing Serial Number: $serialNumber"
    echo "Processing Serial Number: $serialNumber"
    
    token_response=$(curl --silent --location --request POST "${URL}/api/oauth/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${API_Client_ID}" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_secret=${Client_Secret}")
    bearer_token=$(echo "$token_response" | plutil -extract access_token raw -)
    token_expires_in=$(echo "$token_response" | plutil -extract expires_in raw -)
    
    # Check if authToken contains "token"
    if [[ "$token_response" != *"token"* ]]; then
        updateScriptLog "Failed to obtain auth token"
        echo "Failed to obtain auth token"
        failed_serial_numbers+=("$serialNumber")
        return
    fi
    
    if [ -z "$bearer_token" ]; then
        updateScriptLog "Failed to parse auth token"
        echo "Failed to parse auth token"
        failed_serial_numbers+=("$serialNumber")
        return
    fi
    
    # determine Jamf Pro device id
    ID=$(curl -s -H "Accept: application/xml" -H "Authorization: Bearer ${bearer_token}" "${URL}/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '/computer/general/id/text()' - 2>/dev/null)
    
    if [ -z "$ID" ]; then
        updateScriptLog "Failed to obtain device ID for serial number $serialNumber"
        echo "Failed to obtain device ID for serial number $serialNumber"
        failed_serial_numbers+=("$serialNumber")
        return
    fi
    
    updateScriptLog "The JSS ID of this computer is $ID"
    echo "The JSS ID of this computer is $ID"
    
    # Run CURL command that reinstalls management framework
    response=$(curl --request POST \
    --url "$URL/api/v1/jamf-management-framework/redeploy/$ID" \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer $bearer_token" \
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
        failed_serial_numbers+=("$serialNumber")
        return
    fi
    
    # expire the auth token
    /usr/bin/curl "$URL/uapi/auth/invalidateToken" \
    --silent \
    --request POST \
    --header "Authorization: Bearer $bearer_token"
    
    successful_serial_numbers+=("$serialNumber")
}

####################################################################################################
# Main Execution
####################################################################################################

while true; do
    # Display dialog and capture user input
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
        show_no_serials_dialog
        continue
    fi
    
    # Process each serial number
    IFS=',' read -ra serialNumberArray <<< "$serialNumbers"
    for serialNumber in "${serialNumberArray[@]}"; do
        serialNumber=$(echo "$serialNumber" | xargs) # Trim any extra whitespace
        process_serial_number "$serialNumber"
    done
    
    # Show summary dialog with both successful and failed serial numbers
    show_summary_dialog
    userChoice=$?
    
    # Handle user choice
    if [ "$userChoice" -eq 0 ]; then
        # Restart the loop
        failed_serial_numbers=() # Clear failed serial numbers as we are restarting
        successful_serial_numbers=() # Clear successful serial numbers
        continue
    else
        # Quit the application
        exit 0
    fi
done