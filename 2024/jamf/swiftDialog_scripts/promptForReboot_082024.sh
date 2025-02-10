#!/bin/bash

# Author: Tempus Thales
# Contributors: BigMacAdmin@MacAdmins
# Date: 08/06/2024
# Version: 2024.08.06-1.0
# Description: Prompt for Reboot

# Original Script: https://github.com/SecondSonConsulting/swiftDialogExamples/blob/main/promptForRestart.sh
# Notes: I only added very few things needed for a specific project, like the --timer flag and minor cosmetics.

#################################################################
# Pre-flight Checks
#################################################################

# Pre-flight Check: Client-side Logging
scriptLog="/var/log/promptForRestart.log"

if [[ ! -f "${scriptLog}" ]]; then
	touch "${scriptLog}"
fi

# Pre-flight Check: Client-side Script Logging Function
function updateScriptLog() {
	echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# Pre-flight Check: Logging Preamble
scriptVersion="1.0"
updateScriptLog "\n\n###\n# Fast, Good, Cheap (${scriptVersion})\n# https://fastgood.cheap/ \n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# Pre-flight Check: Confirm script is running under bash
if [[ "$BASH" != "/bin/bash" ]] ; then
	updateScriptLog "PRE-FLIGHT CHECK: This script must be run under 'bash', please do not run it using 'sh', 'zsh', etc.; exiting."
	exit 1
fi

# Pre-flight Check: Confirm script is running as root
if [[ $(id -u) -ne 0 ]]; then
	updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
	exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (thanks, Adam!)
# https://github.com/acodega/dialog-scripts/blob/main/dialogCheckFunction.sh
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck(){
	# Get the URL of the latest PKG From the Dialog GitHub repo
	dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	
	# Expected Team ID of the downloaded PKG
	expectedDialogTeamID="PWA5E9TQ59"
	
	# Check for Dialog and install if not found
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		
		updateScriptLog "Dialog not found. Installing..."
		
		# Create temporary working directory
		workDirectory=$( basename "$0" )
		tempDirectory=$( mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		
		# Download the installer package
		curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
		
		# Verify the download
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		
		# Install the package if Team ID validates
		if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
			
			/usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
			
		else
			
			jamfDisplayMessage "Dialog Team ID verification failed."
			exit 1
			
		fi
		
		# Remove the temporary working directory when done
		/bin/rm -Rf "$tempDirectory"  
		
	else
		
		updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."
		
	fi
	
}

dialogCheck

# Main Script
/usr/local/bin/dialog \
--title "Restart Required" \
--titlefont size=22 \
--message "**IMPORTANT** \n\nYour computer requires a restart. \n\nPlease save your work and restart as soon as possible. The system will reboot when the timer runs out." \
--button1text "Restart Now" \
--width 300 --height 400 \
--messagefont size=16 \
--position topright \
--ontop \
--moveable \
--messagealignment centre \
--messageposition centre \
--centericon \
--timer 86400 \
--icon "https://i.imgur.com/CmyJTnq.png"
#--button2
#If you wanted to include a Cancel button, uncomment the line above ^^^

# Capture the output of the dialog. If the user used CMD+Q or the Cancel button then the restart won't happen.
dialogResults=$?

# Check if dialog exited with the default exit code (for the primary button)
if [ "$dialogResults" = 0 ]; then
	# Log the restart event
	updateScriptLog "RESTART INITIATED: User has chosen to restart the computer."

	# This is the restart command. Thank you Dan Snelson: https://snelson.us/2022/07/log-out-restart-shut-down/
	# This mimics the user using the Apple > Restart menu option, so they will get a confirmation and have a chance to save work or cancel.
	# osascript -e 'tell app "loginwindow" to «event aevtrrst»'

	# If you wanted to be less nice you could instead use:
	shutdown -r now
else
	updateScriptLog "RESTART CANCELED: User chose not to restart the computer."
	exit 2
fi

# Footer: Define exit codes
updateScriptLog "SCRIPT COMPLETED: The script has finished executing."
exit 0
