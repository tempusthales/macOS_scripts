#!/bin/bash

# Runs the msupdate command tool to auto-update and patch Microsoft Office 2016 to the latest version.

# Variables
msupdatePath="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS"
currentUser=$(stat -f%Su /dev/console)

# Logic

if [ ! -f "$msupdatePath"/msupdate ]; then
    echo "FAILED: System is not running MS UPDATE 3.18."
    exit 1
fi

if [ ! -f "/Users/$currentUser/Library/Preferences/com.microsoft.autoupdate2.plist" ]; then
    echo "FAILED: could not find the com.microsoft.autoupdate2.plist file to read any preferences."
else
    howToCheck=$(defaults read /Users/$currentUser/Library/Preferences/com.microsoft.autoupdate2 HowToCheck)
    if [ "$howToCheck" != "Manual" ]; then
        defaults write /Users/$currentUser/Library/Preferences/com.microsoft.autoupdate2 HowToCheck Manual
        if [ "$howToCheck" != "Manual" ]; then
            echo "FAILED: Could not reset the how to check preferences to Manual."
        else
            echo "SUCCESSFUL: Changed the how to check preference to Manual."
        fi
    fi
fi

echo "Running Microsoft Updater"
/Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app/Contents/MacOS/msupdate -i

exit 0