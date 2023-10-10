#!/bin/bash

# The work here in this function is heavily influenced from Adam Codega's dialogCheck function - https://github.com/acodega/dialog-scripts/blob/main/dialogCheckFunction.sh
# This function is Bash compatible, insert in your script and then place dockutilCheck where you want it to be executed

function dockutilCheck (){
    # Get the URL of the latest PKG from the DockUtil GitHub repo
    dockutilURL=$(curl --silent --fail "https://api.github.com/repos/kcrawford/dockutil/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    
    # Expected Team ID of the downloaded PKG
    # expectedDialogTeamID="TeamIDGoesHere"

    # Check for DockUtil and install if not found
    if [ ! -e "/usr/local/bin/dockutil" ]; then
        echo "DockUtil not found. Installing..."
        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        #Download the installer package
        /usr/bin/curl --location --silent "$dockutilURL" -o "$tempDirectory/DockUtil.pkg"
        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/DockUtil.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        # Install the package if Team ID validates
        # if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
        #   /usr/sbin/installer -pkg "$tempDirectory/DockUtil.pkg" -target /
        /usr/sbin/installer -pkg "$tempDirectory/DockUtil.pkg" -target /
        # else # uncomment this else if you want your script to exit now if swiftDialog is not installed
            # displayAppleScript # uncomment this if you're using my displayAppleScript function
            # echo "Dialog Team ID verification failed."
            # exit 1
    fi
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  
  else echo "DockUtil found. Proceeding..."
  fi
}
