#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESC:  dockutilCheck function
#
# Developed by: Tempus Thales ~ Austin, TX
# Thanks to Adam Codega and Armin Briegel for knowledge used in this function.
# Adam Codega - https://github.com/acodega and Armin Briegel - https://github.com/scriptingosx
# Start Date: 10/09/2023        End Date: 10/10/2023
#
# Instructions: put this somewhere in your code then call the function later on by typinig dockutilCheck somewhere else
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dockutilCheck (){
    # Get the URL of the latest PKG from the DockUtil GitHub repo
    dockutilURL=$(curl --silent --fail "https://api.github.com/repos/kcrawford/dockutil/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    expectedDialogTeamID="Z5J8CJBUWC" # This is the DEVELOPER ID, not the github TeamID as I thought it was... I was an idiot.

    # Check for DockUtil and install if not found
    if [ ! -e "/usr/local/bin/dockutil" ]; then
        echo "DockUtil not found. Installing..."
        # Create temporary working directory
        workDirectory=$(basename "$0")
        tempDirectory=$(mktemp -d "/private/tmp/$workDirectory.XXXXXX")
        
        # Download the installer package
        if ! /usr/bin/curl --location --silent "$dockutilURL" -o "$tempDirectory/DockUtil.pkg"; then
            echo "Failed to download DockUtil package. Exiting."
            exit 1
        fi

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -t install -vv "$tempDirectory/DockUtil.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        
        # Install the package if Team ID validates
        if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
           /usr/sbin/installer -pkg "$tempDirectory/DockUtil.pkg" -target /
        
        # Install the package if Team ID validates
        if [ -z "$teamID" ]; then
            echo "Team ID verification failed. Exiting."
            exit 1
        fi

        /usr/sbin/installer -pkg "$tempDirectory/DockUtil.pkg" -target /
    # else
        echo "DockUtil found. Proceeding..."
    # fi

    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  
}
