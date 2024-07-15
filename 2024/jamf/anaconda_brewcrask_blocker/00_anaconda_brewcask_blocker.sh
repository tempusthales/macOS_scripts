#!/bin/zsh --no-rcs
# shellcheck shell=bash

####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# Author: Tempus Thales
# Contributors:
# Date: 07/15/2024
# Version: 2024.07.15-1.0
# Description: Anaconda Brew Cask Blocker

# Exit code descriptions
EXIT_SUCCESS=0
EXIT_NOT_ROOT=1
EXIT_WRONG_SHELL=2

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptLog="/var/log/block_anaconda.log"

if [[ ! -f "${scriptLog}" ]]; then
	touch "${scriptLog}"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
	echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function currentLoggedInUser() {
	loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
	updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac (2024.07.10-1.0)\n# https://inside.tesla.com/en-US/help-center#resources-IT\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running under bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "$BASH" != "/bin/bash" ]] ; then
	updateScriptLog "PRE-FLIGHT CHECK: This script must be run under 'bash', please do not run it using 'sh', 'zsh', etc.; exiting."
	exit $EXIT_WRONG_SHELL
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
	updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are NOT running; pausing for 1 second"
	sleep 1
done

updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are running; proceeding …"

# Invoke the function to log current logged-in user
currentLoggedInUser

# Main script starts here

# Define the Homebrew Cask directory
HOMEBREW_CASK_DIR="$(brew --prefix)/Caskroom"

# Check if the Anaconda cask directory exists and remove it if it does
if [ -d "$HOMEBREW_CASK_DIR/anaconda" ]; then
  updateScriptLog "Removing existing Anaconda cask directory..."
  rm -rf "$HOMEBREW_CASK_DIR/anaconda"
  updateScriptLog "Anaconda cask directory removed."
else
  updateScriptLog "Anaconda cask directory not found."
fi

# Make the directory read-only
updateScriptLog "Making the Anaconda cask directory read-only..."
mkdir -p "$HOMEBREW_CASK_DIR/anaconda"
chmod -R 555 "$HOMEBREW_CASK_DIR/anaconda"
updateScriptLog "Anaconda cask directory is now read-only."

# Create a custom Homebrew tap directory
CUSTOM_TAP_DIR=~/homebrew-taps/my-cask-block
mkdir -p "$CUSTOM_TAP_DIR/Casks"

# Create the fake Anaconda cask file
FAKE_CASK_FILE="$CUSTOM_TAP_DIR/Casks/anaconda.rb"
cat <<EOF > "$FAKE_CASK_FILE"
cask 'anaconda' do
  version 'blocked'
  sha256 'blocked'

  url 'https://example.com/blocked'
  name 'Anaconda'
  desc 'This cask is blocked by your administrator'
  homepage 'https://www.anaconda.com/'

  caveats <<~EOS
    Anaconda installation is blocked by your administrator.
  EOS
end
EOF

updateScriptLog "Fake Anaconda cask file created at $FAKE_CASK_FILE."

# Add the custom tap to Homebrew
updateScriptLog "Adding custom tap to Homebrew..."
brew tap-new my-cask-block
brew tap my-cask-block "$CUSTOM_TAP_DIR"
updateScriptLog "Custom tap added to Homebrew."

updateScriptLog "Anaconda cask blocking setup is complete."

exit $EXIT_SUCCESS

####################################################################################################
#
# Exit Code Descriptions
#
####################################################################################################
# 0 - Success
# 1 - Script must be run as root
# 2 - Script must be run under bash
####################################################################################################