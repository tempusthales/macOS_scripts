#!/bin/bash

# Variables

# Get the current version of clang 
currentClangVersion=$(/usr/bin/clang --version | awk '{print $5}' | cut -c 8- | rev | cut -c 2- | rev )

# What is version of clang for macOS Monterey
requiredClangVersion="1300.0.29.30"

# Is the device on macOS Monterey
if [[ $(sw_vers -buildVersion) > "21" ]]; then
	echo "This device is on macOS Monterey"
	currentOS="12"
else
	echo "This device is NOT on macOS Monterey"
fi


# If device is on Monterey and the version of Clang does not match, remove Xcode CLT and reinstall

if [[ "$currentOS" = "12" && "$currentClangVersion" != "$requiredClangVersion" ]]; then
	xcodeVersion="On macOS Monterey but not current Xcode"
	echo "$xcodeVersion"
	/bin/rm -rf /Library/Developer/CommandLineTools
	sleep 10
	echo "Apple Command Line Developer Tools removed or not found."
	touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
	installationPKG=$(/usr/sbin/softwareupdate --list | /usr/bin/grep -B 1 -E 'Command Line Tools' | /usr/bin/tail -2 | /usr/bin/awk -F'*' '/^ *\\*/ {print $2}' | /usr/bin/sed -e 's/^ *Label: //' -e 's/^ *//' | /usr/bin/tr -d '\n')
	echo "Installing ${installationPKG}"
	/usr/sbin/softwareupdate --install "${installationPKG}" --verbose
else
	xcodeVersion="Has correct version of Xcode"
	echo "$xcodeVersion"
fi

exit 0