#!/bin/bash

#####################################################################################
# Name:                       pw_sys_wide_prefs.sh
# Author:                      Tempus Thales
# Purpose:                    Require local admin password to access system wide prefs
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.system_access.log"

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

#####################################################################################
# Require local admin password to access system wide prefs
#####################################################################################
logMessage "Script Started"

# Require Admin PW to access system wide Preferences
security authorizationdb read system.preferences > /tmp/system.preferences.plist
/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
if [[ $(/usr/libexec/PlistBuddy -c "Print :shared" /tmp/system.preferences.plist) == "false" ]]; then
  # make edit to authorizationdb
  security authorizationdb write system.preferences < /tmp/system.preferences.plist
  logMessage "Successfully set requirement for local admin password to access system wide preferences. Deleting temp file and exiting..."
  # delete temp file /tmp/system.preferences.plist
  rm -f /tmp/system.preferences.plist
  exit 0
else
  logMessage "Failed to set requirement for local admin password to access system wide prefs! Deleting temp file and exiting with error..."
  # delete temp file /tmp/system.preferences.plist
  rm -f /tmp/system.preferences.plist
  exit 1
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
echo "Erroneously arrived at end of script..."
logMessage "Erroneously arrived at end of script..."
exit 2
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == Successful run
# exit 1 == Failed to set requirement for local admin password to access system wide prefs
# exit 2 == Arrived at end of script erroneously, check script for errors
