#!/bin/bash

# Author: Tempus Thales
# Updated 09/06/2022

# macOS Erase and Install script for Apple Silicon
# Note: This assumes that "Install macOS Monterey.app" is in /Applications

# Check to see if Managed Admin/Local admin has a Secure Boot Token

# Get the Username of the currently logged user
loggedInUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')

# Get the id of the currently logged user for use in a Jamf Policy
userID=$(id -u "$loggedInUser")

# Get SecureTokenStaus
# Note: systemctl does not use standard output. Use 2>&1 to force standard out
status=$(sysadminctl -secureTokenStatus "$loggedInUser" 2>&1 | /usr/bin/awk '/Secure token is/{print $7}')


# If statement to see if the logged in user has a Secure Token then continue to update or upgrade Mac with startosinstall

if [[ "$status" != "ENABLED" ]]; then
	echo "Logged in user does not have a Secure Token"
	exit 0
else
	password=$(osascript -e 'text returned of (display dialog "Please Enter Your Password" with hidden answer default answer "" buttons {"OK"} default button 1)')
	echo "$password" | /Applications/Install\ macOS\ Monterey.app/Contents/Resources/startosinstall --eraseinstall --agreetolicense --forcequitapps --newvolumename "Mac HD" --user "$loggedInUser" --stdinpass &
fi
