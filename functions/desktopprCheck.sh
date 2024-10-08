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