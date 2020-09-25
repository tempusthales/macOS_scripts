#!/bin/bash

#####################################################################################
# Name:                       disable_login_other_sessions.sh
# Purpose:                    Disables login to other active user sessions on the device
#                             and additionally allows use of TouchID for unlock if enabled
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.system_access.log"

logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d..%H:%M:%S-%z) 2>&1)"
  user="$((who -m | awk '{print $1;}') 2>&1)"
  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  else
    # write local logs
    echo "$date_set    $user    ${0##*/}    $1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  fi
}

# Read security authorizationdb and direct to a file
security authorizationdb read system.login.screensaver > /private/var/tmp/com.company_name.security_auth_tmp.plist

# verify /private/var/tmp/com.company_name.security_auth_tmp.plist exists
if [[ -f /private/var/tmp/com.company_name.security_auth_tmp.plist ]]; then
  logMessage "Successfully created /private/var/tmp/com.company_name.security_auth_tmp.plist"
else
  logMessage "Failed to create /private/var/tmp/com.company_name.security_auth_tmp.plist!"
  logMessage "Exiting with error..."
  exit 1
fi

logMessage "Editing /private/var/tmp/com.company_name.security_auth_tmp.plist to include authenticate-session-owner"

# clear contents of the "rule" array
while [[ ! $(/usr/libexec/PlistBuddy -c "Print :rule:0" /private/var/tmp/com.company_name.security_auth_tmp.plist 2>&1) =~ 'Print: Entry, ":rule:0", Does Not Exist' ]]; do
  logMessage "Deleting existing string in *rule* array: $(/usr/libexec/PlistBuddy -c "Print :rule:0" /private/var/tmp/com.company_name.security_auth_tmp.plist)"
  /usr/libexec/PlistBuddy -c "Delete :rule:0" /private/var/tmp/com.company_name.security_auth_tmp.plist
done
logMessage "Contents of *rule* array in /private/var/tmp/system.login.screensaver.plist cleared"

# edit /private/var/tmp/com.company_name.security_auth_tmp.plist
logMessage "Adding *authenticate-session-owner* to position 0 in *rule* array in /private/var/tmp/system.login.screensaver.plist cleared..."
/usr/libexec/PlistBuddy -c "Add :rule:0 string authenticate-session-owner" /private/var/tmp/com.company_name.security_auth_tmp.plist
logMessage "Adding *use-login-window-ui* to position 1 in *rule* array in /private/var/tmp/system.login.screensaver.plist cleared..."
/usr/libexec/PlistBuddy -c "Add :rule:1 string use-login-window-ui" /private/var/tmp/com.company_name.security_auth_tmp.plist
# verify edit of /private/var/tmp/com.company_name.security_auth_tmp.plist
if [[ $(/usr/libexec/PlistBuddy -c "Print :rule:0" /private/var/tmp/com.company_name.security_auth_tmp.plist) == "authenticate-session-owner" ]] && [[ $(/usr/libexec/PlistBuddy -c "Print :rule:1" /private/var/tmp/com.company_name.security_auth_tmp.plist) == "use-login-window-ui" ]]; then
  # make edit to authorizationdb
  logMessage "Writing /private/var/tmp/com.company_name.security_auth_tmp.plist to security authorizationdb..."
  security authorizationdb write system.login.screensaver < /private/var/tmp/com.company_name.security_auth_tmp.plist

  # test security authorizationdb for edited array contents
  arrrayModification1=$(security authorizationdb read system.login.screensaver | grep "<string>authenticate-session-owner</string>")
  arrrayModification2=$(security authorizationdb read system.login.screensaver | grep "<string>use-login-window-ui</string>")

  if [[ "$arrrayModification1" == "" ]] || [[ "$arrrayModification2" == "" ]]; then
    logMessage "Failed to write /private/var/tmp/com.company_name.security_auth_tmp.plist to security authorizationdb!"
    logMessage "Deleting /private/var/tmp/com.company_name.security_auth_tmp.plist and exiting with error..."
    rm -f /private/var/tmp/com.company_name.security_auth_tmp.plist
    exit 2
  else
    logMessage "Security authorizationdb has been set for session-owner-only authentication using login window UI"
    logMessage "Deleting /private/var/tmp/com.company_name.security_auth_tmp.plist"
    rm -f /private/var/tmp/com.company_name.security_auth_tmp.plist
    logMessage "Script completed successfully. Exiting..."
    exit 0
  fi
else
  logMessage "Failed to succesfully modify /private/var/tmp/com.company_name.security_auth_tmp.plist!"
  logMessage "Deleting /private/var/tmp/com.company_name.security_auth_tmp.plist and exiting with error..."
  rm -f /private/var/tmp/com.company_name.security_auth_tmp.plist
  exit 3
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
echo "Erroneously arrived at end of script..."
logMessage "Erroneously arrived at end of script..."
exit 4
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == Successful run
# exit 1 == Failed to create /private/var/tmp/com.company_name.security_auth_tmp.plist
# exit 2 == Failed to successfully set authenticate-session-owner to unlock the screen
# exit 3 == Failed to modify /private/var/tmp/com.company_name.security_auth_tmp.plist properly with PlistBuddy
# exit 4 == Arrived at end of script erroneously, check script for errors
