#!/bin/bash

#####################################################################################
# Name:                       disable_bonjour.sh
# Purpose:                    Disables Bonjour advertising on the computer
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.network.log"

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

logMessage "Script Started"
#####################################################################################
# Disable Bonjour multicast advertising service
#####################################################################################
# check current status of Bonjour advertising service
if [[ $(defaults read /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements) == 1 ]]; then
  logMessage "Bonjour multicast advertising service is already disabled"
  logMessage "Script complete. Exiting..."
  exit 0
else
  # disable Bonjour advertising service if not already disabled
  defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool YES
  # verify disablement
  if [[ $(defaults read /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements) == 1 ]]; then
    logMessage "Bonjour has been disabled"
    logMessage "Script complete. Exiting..."
    exit 0
  else
    logMessage "Failed to disable Bonjour multicast advertisements!"
    logMessage  "Exiting with error..."
    exit 1
  fi
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 2
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == failed to disable Bonjour multicast advertisements
# exit 2 == arrived at end of script erroneously, check script for errors
