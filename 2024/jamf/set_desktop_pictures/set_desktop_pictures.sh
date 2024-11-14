#!/bin/zsh

# Author: Tempus Thales   
# Contributors
# Date: 11/14/2024
# Version: 2024-11-1.0
# Description: Sets up Desktop Picture for logged in user

# Boring Variables
currentUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }' )
desktoppr="/usr/local/bin/desktoppr"

# Client-side Logging
#####################
scriptVersion="1.0"
scriptLog="/var/log/company/desktoppr-wallpaper.log"

# Ensure the log directory exists
if [[ ! -d "/var/log/company" ]]; then
	mkdir -p "/var/log/company"
fi

if [[ ! -f "${scriptLog}" ]]; then
	touch "${scriptLog}"
fi

# Log update function
function updateScriptLog() {
	echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

updateScriptLog "\n\n###\n# Setup Desktop Pictures (${scriptVersion})\n# https://support.company.com\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"


# Pre-Flight Checks
#####################

# Pre-Flight Check if there's a user logged in
if [ -z "$currentUser" ] || [ "$currentUser" = "loginwindow" ]; then
	updateScriptLog "No user logged in, cannot proceed"
	exit 1
fi

# Pre-flight Check if Desktoppr is installed
function desktopprCheck() {
	desktopprURL=$(curl --silent --fail "https://api.github.com/repos/scriptingosx/desktoppr/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	expectedDesktopprTeamID="JME5BW3F3R"
	if [ ! -e "/usr/local/bin/desktoppr" ]; then
		echo "Desktoppr not found. Installing..."
		workDirectory=$( /usr/bin/basename "$0" )
		tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		/usr/bin/curl --location --silent "$desktopprURL" -o "$tempDirectory/Desktoppr.pkg"
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Desktoppr.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		if [ "$expectedDesktopprTeamID" = "$teamID" ] || [ "$expectedDesktopprTeamID" = "" ]; then
			/usr/sbin/installer -pkg "$tempDirectory/Desktoppr.pkg" -target /
		else
			echo "Desktoppr Team ID verification failed."
			exit 1
		fi
		/bin/rm -Rf "$tempDirectory"
	else
		echo "Desktoppr is already installed. Proceeding..."
	fi
}

if [[ ! -x ${desktoppr} ]]; then
	echo "couldn't find desktoppr, installing..."
	desktopprCheck
fi

# Source and destination directories
sourceDir="/opt/company/wallpapers"
desktop_photos="/Users/$currentUser/Library/Application Support/com.apple.desktop.photos"

# Script Begins
#####################

# Check if source directory exists
if [ ! -d "$sourceDir" ]; then
	updateScriptLog "Source directory does not exist: $sourceDir"
	exit 1
fi

# Check if destination directory exists, if not create it
if [ ! -d "$desktop_photos" ]; then
	updateScriptLog "Destination directory does not exist, creating it: $desktop_photos"
	if mkdir -p "$desktop_photos"; then
		updateScriptLog "Destination directory created successfully."
	else
		updateScriptLog "Failed to create destination directory."
		exit 1
	fi
fi

# Check for existing content in the destination directory
if [ -n "$(ls -A "${desktop_photos:?}")" ]; then
	updateScriptLog "Content found in $desktop_photos. Removing existing content..."
	if rm -rf "${desktop_photos:?}"/*; then
		updateScriptLog "Existing content removed successfully."
	else
		updateScriptLog "Failed to remove existing content."
		exit 1
	fi
else
	updateScriptLog "No existing content in $desktop_photos."
fi

# Log directory contents
updateScriptLog "Source directory contents:"
ls -la "$sourceDir" >> "${scriptLog}" 2>&1
updateScriptLog "Destination directory contents (before move):"
ls -la "$desktop_photos" >> "${scriptLog}" 2>&1

# Copy new files from source to destination
if [ -n "$(ls -A "$sourceDir")" ]; then
	updateScriptLog "Moving files from $sourceDir to $desktop_photos..."
	if mv "$sourceDir"/* "${desktop_photos:?}"; then
		updateScriptLog "Files moved successfully!"
	else
		updateScriptLog "Error occurred during the file move."
		exit 1
	fi
else
	updateScriptLog "Source directory is empty. No files to move."
fi

# Log final directory contents
updateScriptLog "Destination directory contents (after move):"
ls -la "$desktop_photos" >> "${scriptLog}" 2>&1

# Check and fix file permissions
#####################
function checkAndFixPermissions() {
	updateScriptLog "Checking and fixing permissions for $desktop_photos..."
	
	# Ensure the current user owns the destination directory and its contents
	if chown -R "$currentUser:staff" "$desktop_photos"; then
		updateScriptLog "Ownership updated successfully."
	else
		updateScriptLog "Failed to update ownership."
		exit 1
	fi
	
	# Set appropriate permissions: read and write for the user, and read-only for others
	if chmod -R 755 "$desktop_photos"; then
		updateScriptLog "Permissions updated successfully."
	else
		updateScriptLog "Failed to update permissions."
		exit 1
	fi
}

# Run the function to check and fix permissions
checkAndFixPermissions

# Desktop Setup
#####################

# Get the current user's UID
uid=$(id -u "$currentUser")

# Function to run a command as the current user
runAsUser() {  
	if [ "$currentUser" != "loginwindow" ]; then
		launchctl asuser "$uid" sudo -u "$currentUser" "$@"
	else
		updateScriptLog "No user logged in"
		exit 1
	fi
}

# Randomly select a wallpaper
rotateDP="$(find "$desktop_photos" -type f | sort -R | head -n 1)"

# Run desktoppr to change the desktop desktop_photos
runAsUser $desktoppr "$rotateDP"

# Deploy the LaunchDaemon
#####################

# Define the path for the LaunchDaemon plist
launchDaemonPlist="/Library/LaunchDaemons/com.company.desktoppr.launchdaemon.plist"

# Check if the plist exists and delete it if it does
if [ -f "$launchDaemonPlist" ]; then
	updateScriptLog "Deleting existing LaunchDaemon plist..."
	rm "$launchDaemonPlist"
fi

# Create the LaunchDaemon plist
cat > "$launchDaemonPlist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
		<key>Label</key>
		<string>com.company.desktoppr.launchdaemon</string>
		<key>ProgramArguments</key>
		<array>
				<string>/usr/local/bin/desktoppr</string>
				<string>$rotateDP</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
		<key>KeepAlive</key>
		<false/>
		<key>UserName</key>
		<string>root</string>
</dict>
</plist>
EOF

# Set the correct permissions for the LaunchDaemon plist
chmod 644 "$launchDaemonPlist"
chown root:wheel "$launchDaemonPlist"

# Load the LaunchDaemon
updateScriptLog "Loading the LaunchDaemon..."
launchctl bootstrap system "$launchDaemonPlist"

exit 0
