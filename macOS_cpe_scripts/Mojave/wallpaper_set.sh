#!/bin/bash

#####################################################################################
# Name:                       wallpaper_set.sh
# Author:		      Tempus Thales
# Purpose:                    Sets wallpaper based on current language selection
# Notes:                      Requires Jamf config profile forcing specific wallpaper path: /Library/Desktop\ Pictures/company_name_wallpaper.jpg
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.wallpaper.log"

logMessage() {
  # Ensure log_path is set
  [ -z "$log_path" ] && log_path="/var/log/default"

  mkdir -p "$log_path"

  # Correct command substitution
  date_set="$(date +%Y-%m-%d..%H:%M:%S-%z 2>&1)"
  user="$(who -m | awk '{print $1;}' 2>&1)"

  if [[ -z "$log_file" ]]; then
    # Write to stdout (captured by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  else
    # Write to local logs
    echo "$date_set    $user    ${0##*/}    $1" >> "$log_path/$log_file"
    # Also write to stdout
    echo "$date_set    $user    ${0##*/}    $1"
  fi
}

logMessage "Starting script..."
#####################################################################################
# Acquire variables related to user
#####################################################################################
# get currently logged in user
# currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# get user's home folder
currentUserHome=$(dscl . -read /Users/$currentUser NFSHomeDirectory | cut -d " " -f 2)
#####################################################################################
# Get system language for current user
#####################################################################################
# get current langage, replace _ with - to match deployed folder names list
locale=$(defaults read $currentUserHome/Library/Preferences/.GlobalPreferences AppleLocale | tr '[:upper:]' '[:lower:]' | tr '_' '-')
if [[ "$locale" == "" ]]; then
	logMessage "No locale found, defaulting to en-us."
  locale="en-us"
else
	logMessage "Locale for $currentUser set to: $locale"
fi
#####################################################################################
# Set the directory for the wallpapers to be chosen from
#####################################################################################
# check for company_name wallpapers in user's default language
if [[ -d "/Library/Desktop Pictures/$locale/" ]]; then
	logMessage "Found company_name wallpapers directory for locale: $locale"
else
  # if wallpapers in default language do not exist, set default to en
	logMessage "No wallpapers found for locale: $locale."
  logMessage "Defaulting to en-us."
	locale="en-us"
	if [[ ! -d "/Library/Desktop Pictures/$locale/" ]]; then
		logMessage "company_name $locale wallpapers not found!"
    logMessage "Exiting with error..."
		exit 1
	fi
fi

# set directory to pull wallpaper from
wallpaperDirectory="/Library/Desktop Pictures/$locale"
logMessage "Wallpaper will be chosen from directory $wallpaperDirectory"

# determine current screen resolution
screenResolution=$(echo "$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2}')x$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $4}')")

# see if a wallpaper exists in the current screen resolution and language combination
if [[ -f "$wallpaperDirectory/${screenResolution}_${locale}_company_name_wallpaper.jpg" ]]; then
  logMessage "A wallpaper exists with matching resolution to primary display: $screenResolution"
  # set $chosenWallpaper to existing company_name wallpaper file with correct resolution
  chosenWallpaper="$wallpaperDirectory/${screenResolution}_${locale}_company_name_wallpaper.jpg"
  # delete existing file if it exists
  rm -f "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
  # copy $chosenWallpaper to /Library/Desktop\ Pictures/company_name_wallpaper.jpg
  cp "$chosenWallpaper" "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
  # verify that file was copied
  if [[ $(ls -alh "/Library/Desktop Pictures/.company_name_wallpaper.jpg" | awk '{print $6,$7,$8}') == "" ]]; then
    logMessage "/Library/Desktop Pictures/.company_name_wallpaper.jpg does not exist"
    logMessage "Exiting with error..."
    exit 2
  else
    logMessage "Setting ownership and permissions for /Library/Desktop Pictures/.company_name_wallpaper.jpg"
    chown root:wheel "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
    chown 644 "/Library/Desktop Pictures/.company_name_wallpaper.jpg"

    logMessage "$chosenWallpaper was copied to /Library/Desktop Pictures/.company_name_wallpaper.jpg on $(ls -alh "/Library/Desktop Pictures/.company_name_wallpaper.jpg" | awk '{print $6,$7,$8}')"
    logMessage "Killing Dock process to refresh Desktop"
    killall Dock
    logMessage "Script completed successfully"
    logMessage "Exiting..."
    exit 0
  fi
else
  logMessage "No existing $locale wallpaper in $screenResolution!"
  logMessage "Setting wallpaper to default $locale 2560x1600 resolution (13 retina)"
  # default resolution will be 2560x1600 (13" retina)
  chosenWallpaper="$wallpaperDirectory/2560x1600_${locale}_company_name_wallpaper.jpg"
  # delete existing file if it exists
  rm -f "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
  # copy $chosenWallpaper to /Library/Desktop\ Pictures/company_name_wallpaper.jpg
  cp "$chosenWallpaper" "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
  # verify that file was copied
  if [[ $(ls -alh "/Library/Desktop Pictures/.company_name_wallpaper.jpg" | awk '{print $6,$7,$8}') == "" ]]; then
    logMessage "/Library/Desktop Pictures/.company_name_wallpaper.jpg does not exist"
    logMessage "Exiting with error..."
    exit 2
  else
    logMessage "Setting ownership and permissions for /Library/Desktop Pictures/.company_name_wallpaper.jpg"
    chown root:wheel "/Library/Desktop Pictures/.company_name_wallpaper.jpg"
    chown 644 "/Library/Desktop Pictures/.company_name_wallpaper.jpg"

    logMessage "$chosenWallpaper was copied to /Library/Desktop Pictures/.company_name_wallpaper.jpg on $(ls -alh "/Library/Desktop Pictures/.company_name_wallpaper.jpg" | awk '{print $6,$7,$8}')"
    logMessage "Killing Dock process to refresh Desktop"
    killall Dock
    logMessage "Script completed successfully"
    logMessage "Exiting..."
    exit 0
  fi
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 3
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == company_name default wallpaper not found
# exit 2 == Failed to create /Library/Desktop Pictures/.company_name_wallpaper.jpg
# exit 3 == arrived at end of script erroneously, check script for errors
