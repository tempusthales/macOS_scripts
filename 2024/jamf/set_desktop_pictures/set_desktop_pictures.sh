#!/bin/zsh

# Author: Tempus Thales   
# Contributors
# Date: 09-20-2024
# Version: 2024-09-1.2
# Description: Sets up Desktop Picture for logged in user

# Pre-flight Checks
#####################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
scriptVersion="1.2"
scriptLog="/var/log/company/desktoppr-wallpaper.log"

# Check if the log directory exists, if not create it
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
updateScriptLog "\n\n###\n# Setup Desktop Pictures (${scriptVersion})\n# https://support.company.com\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}

# Get the current logged-in user
currentLoggedInUser

# Check if Desktoppr is installed
function desktopprCheck() {
    # Get the URL of the latest PKG from the Desktoppr GitHub repo
    desktopprURL=$(curl --silent --fail "https://api.github.com/repos/scriptingosx/desktoppr/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    
    # Expected Team ID of the downloaded PKG
    expectedDesktopprTeamID="JME5BW3F3R"  # Replace with the actual expected Team ID for Desktoppr
    
    # Check if Desktoppr is installed in /usr/local/bin
    if [ ! -e "/usr/local/bin/desktoppr" ]; then
        echo "Desktoppr not found. Installing..."
        
        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        
        # Download the installer package
        /usr/bin/curl --location --silent "$desktopprURL" -o "$tempDirectory/Desktoppr.pkg"
        
        # Verify the download by checking the Team ID
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Desktoppr.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        
        # Install the package if Team ID validates
        if [ "$expectedDesktopprTeamID" = "$teamID" ] || [ "$expectedDesktopprTeamID" = "" ]; then
            /usr/sbin/installer -pkg "$tempDirectory/Desktoppr.pkg" -target /
        else
            echo "Desktoppr Team ID verification failed."
            exit 1
        fi
        
        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"
    else
        echo "Desktoppr is already installed. Proceeding..."
    fi
}

# change this path to match the location on your system
desktop_pictures="/Library/Desktop Pictures/"
desktoppr="/usr/local/bin/desktoppr"

if [[ ! -x ${desktoppr} ]]; then
    echo "couldn't find desktoppr, installing..."
    desktopprCheck
fi

# Run desktoppr as the logged-in user
if [[ -n "${loggedInUser}" ]]; then
    uid=$(id -u "${loggedInUser}")
    updateScriptLog "Setting desktop for user: ${loggedInUser} (UID: ${uid})"
    
    # Monterey and later behavior
    if [[ "$(sw_vers -buildVersion)" > "21" ]]; then
        launchctl asuser "${uid}" sudo -u "${loggedInUser}" "${desktoppr}" "${desktop_pictures}"
    else
        sudo -u "${loggedInUser}" launchctl asuser "${uid}" "${desktoppr}" "${desktop_pictures}"
    fi
else
    updateScriptLog "No user logged in, skipping desktop set"
fi

# set the desktop pictures
if [[ -f ${desktop_pictures} ]]; then
    ${desktoppr} ${desktop_pictures}
    sleep 0.1
    ${desktoppr} scale center
fi


exit 0