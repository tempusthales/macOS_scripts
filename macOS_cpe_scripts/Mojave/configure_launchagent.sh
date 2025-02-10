#!/bin/bash

#####################################################################################
# Name:                       configure_launchagent.sh
# Purpose:                    Configures launch agent(s)
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.logging.log"

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

logMessage "Script Started"
#####################################################################################
# Create /Library/.company_name/Scripts/ if needed
#####################################################################################
if [[ -d /Library/.company_name/Scripts/ ]]; then
  logMessage "/Library/.company_name/Scripts/ already exists"
else
  # create company_name Scripts directory and set ownership & permissions
  mkdir -p /Library/.company_name/Scripts/
  chown root:wheel /Library/.company_name/Scripts/
  chmod 755 /Library/.company_name/Scripts/
  if [[ -d /Library/.company_name/Scripts/ ]]; then
    logMessage "/Library/.company_name/Scripts/ created successfully"
  else
    logMessage "Failed to create /Library/.company_name/Scripts/"
    logMessage "Exiting with error..."
    exit 1
  fi
fi
#####################################################################################
# Create /Library/.company_name/Scripts/com.company_name.login.sh
#####################################################################################
# create /Library/.company_name/Scripts/com.company_name.login.sh
# this will overwrite an existing version of this file -- this is intended behavior
cat > /Library/.company_name/Scripts/com.company_name.login.sh << 'EOF'
#!/bin/bash

# set login keychain to lock after X minutes of inactivity and lock when sleeping
security set-keychain-settings -l -t 21600 ~/Library/Keychains/login.keychain

# remove read / write from User home folder for group and others.
chmod -R og-rw ~

# turn on file name extensions if not enabled
if [[ $(defaults read NSGlobalDomain AppleShowAllExtensions) != 1 ]]; then
  defaults write NSGlobalDomain AppleShowAllExtensions -bool TRUE
fi

exit 0
EOF

logMessage "Setting permissions and ownership for /Library/.company_name/Scripts/com.company_name.login.sh"
chown root:wheel /Library/.company_name/Scripts/com.company_name.login.sh
chmod 755 /Library/.company_name/Scripts/com.company_name.login.sh

# verifications and exit with error
if [[ -f /Library/.company_name/Scripts/com.company_name.login.sh ]]; then
  logMessage "/Library/.company_name/Scripts/com.company_name.login.sh was created/modified on $(ls -alh /Library/.company_name/Scripts/com.company_name.login.sh | awk '{print $6,$7,$8}')"
else
  logMessage "Failed to create /Library/.company_name/Scripts/com.company_name.login.sh!"
  exit 2
fi
#####################################################################################
# Create /Library/LaunchAgents/com.company_name.login.plist Launch Agent
#####################################################################################
# create /Library/LaunchAgents/com.company_name.login.plist
# this will overwrite an existing version of this file -- this is intended behavior
cat > /Library/LaunchAgents/com.company_name.login.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.company_name.login</string>
	<key>ProgramArguments</key>
	<array>
		<string>/Library/.company_name/Scripts/com.company_name.login.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

logMessage "Setting permissions and ownership for /Library/LaunchAgents/com.company_name.login.plist"
chown root:wheel /Library/LaunchAgents/com.company_name.login.plist
chmod 644 /Library/LaunchAgents/com.company_name.login.plist
# verifications and exit with error
if [[ -f /Library/LaunchAgents/com.company_name.login.plist ]]; then
  logMessage "/Library/LaunchAgents/com.company_name.login.plist was created/modified on $(ls -alh /Library/LaunchAgents/com.company_name.login.plist | awk '{print $6,$7,$8}')"
else
  logMessage "Failed to create /Library/LaunchAgents/com.company_name.login.plist!"
  exit 3
fi

logMessage "Successfully arrived at end of script"
logMessage "Exiting..."
exit 0
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 4
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == failure to create /Library/.company_name/Scripts/
# exit 2 == failure to create /Library/.company_name/Scripts/com.company_name.login.sh
# exit 3 == failure to create /Library/LaunchAgents/com.company_name.login.plist
# exit 4 == arrived at end of script erroneously, check script for errors
