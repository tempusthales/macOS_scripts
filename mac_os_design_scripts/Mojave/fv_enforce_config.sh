#!/bin/bash

#####################################################################################
# Name:                       fv_enforce_config.sh
# Purpose:                    Forces the user to encrypt their endpoint at login or kicks them out.
# Notes:                      Creates FileVault enforcement script and Launch Daemons
#####################################################################################
# LOG GLOBAL VARIABLES
#####################################################################################
log_path="/var/log/company_name"
log_file="com.company_name.fv.enforce.logging.log"

#####################################################################################
# ACQUIRE VARIABLES RELATED TO USER
#####################################################################################
# currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#####################################################################################
# ESTABLISH STANDARDIZED LOCAL LOGGING LOGIC
#####################################################################################
logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d..%H:%M:%S-%z) 2>&1)"

  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $currentUser    ${0##*/}    $1"
  else
    # write local logs
    echo "$date_set    $currentUser    ${0##*/}    $1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $currentUser    ${0##*/}    $1"
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
# Create /Library/.company_name/Scripts/fv_enforce.sh
#####################################################################################
# create /Library/.company_name/Scripts/fv_enforce.sh
# this will overwrite an existing version of this file -- this is intended behavior
cat > /Library/.company_name/Scripts/fv_enforce.sh << 'EOF'
#!/bin/bash

#------------------------------------------------------------------------------------
# Name:                       fv_enforce.sh
# Purpose:                    Verifies user has encrypted his endpoint and if not forces a reboot to initiate encryption process.
#------------------------------------------------------------------------------------

#####################################################################################
# LOG GLOBAL VARIABLES
#####################################################################################
log_path="/var/log/company_name"
log_file="com.company_name.fv.enforce.logging.log"
#####################################################################################
# ACQUIRE VARIABLES RELATED TO USER
#####################################################################################
currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#####################################################################################
# ESTABLISH STANDARDIZED LOCAL LOGGING LOGIC
#####################################################################################
logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d..%H:%M:%S-%z) 2>&1)"

  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $currentUser    ${0##*/}    $1"
  else
    # write local logs
    echo "$date_set    $currentUser    ${0##*/}    $1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $currentUser    ${0##*/}    $1"
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
# MAIN SCRIPT
#####################################################################################

# If user returns root (no one is logged in) or company_nameadmin (Jamf post image account) then exit
if [[ $currentUser == "root" ]] || [[ $currentUser == "company_nameadmin" ]]; then
logMessage "Either no one is logged in or company_nameadmin is logged in, exiting..."
  exit 1
fi

# Identify current FileVault status
FV_STATUS=$(fdesetup status | grep "FileVault is On.")

# If FV_STATUS returns "FileVault is On." - remove /.fvtmp folder and exit
if [[ -n $FV_STATUS ]]; then
  logMessage "$FV_STATUS"
  rm -rf /.fvtmp
  if [[ -d /.fvtmp ]]; then
    logMessage "Successfully deleted /.fvtmp"
  else
    logMessage "Failed to delete /.fvtmp"
  fi
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
else
  logMessage "Endpoint not encrypted!"

  # Create /.fvtmp directory if it doesn't exist
  mkdir -p /.fvtmp

  # verify
  if [[ -d /.fvtmp ]]; then
    logMessage "Created /.fvtmp directory"

    # Force deferred encryption and reboot for current user with forced encryption on next login
    logMessage "Forcing deferred encryption for $currentUser and rebooting computer for current user with forced encryption on next login."

    fdesetup enable -user $currentUser -forceatlogin 0 -forcerestart -defer /.fvtmp/fv.plist
    sleep 5
    exit 0
  else
    logMessage "Failed to create /.fvtmp"
    logMessage "Exiting with error..."
    exit 2
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
# exit 1 == either root or company_nameadmin is logged in.
# exit 2 == Failed to create /.fvtmp
# exit 3 == arrived at end of script erroneously, check script for errors
EOF

logMessage "Setting permissions and ownership for /Library/.company_name/Scripts/fv_enforce.sh"
chown root:wheel /Library/.company_name/Scripts/fv_enforce.sh
chmod 755 /Library/.company_name/Scripts/fv_enforce.sh

# verifications and exit with error
if [[ -f /Library/.company_name/Scripts/fv_enforce.sh ]]; then
  logMessage "/Library/.company_name/Scripts/fv_enforce.sh was created/modified on $(ls -alh /Library/.company_name/Scripts/fv_enforce.sh | awk '{print $6,$7,$8}')"
else
  logMessage "Failed to create /Library/.company_name/Scripts/fv_enforce.sh!"
  exit 2
fi
#####################################################################################
# Create /Library/LaunchDaemons/com.company_name.fv_enforce.plist Launch Agent
#####################################################################################
# create /Library/LaunchDaemons/com.company_name.fv_enforce.plist
# this will overwrite an existing version of this file -- this is intended behavior
cat > /Library/LaunchDaemons/com.company_name.fv_enforce.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.company_name.fv_enforce</string>
	<key>ProgramArguments</key>
	<array>
		<string>/Library/.company_name/Scripts/fv_enforce.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
  <key>StartInterval</key>
  <integer>10</integer>
</dict>
</plist>
EOF

logMessage "Setting permissions and ownership for /Library/LaunchDaemons/com.company_name.fv_enforce.plist"
chown root:wheel /Library/LaunchDaemons/com.company_name.fv_enforce.plist
chmod 644 /Library/LaunchDaemons/com.company_name.fv_enforce.plist
# verifications and exit with error
if [[ -f /Library/LaunchDaemons/com.company_name.fv_enforce.plist ]]; then
  logMessage "/Library/LaunchDaemons/com.company_name.fv_enforce.plist was created/modified on $(ls -alh /Library/LaunchDaemons/com.company_name.fv_enforce.plist | awk '{print $6,$7,$8}')"
else
  logMessage "Failed to create /Library/LaunchDaemons/com.company_name.fv_enforce.plist!"
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
