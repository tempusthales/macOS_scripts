#!/bin/bash

#####################################################################################
# Name:                       disable_auto_timezone.sh
# Purpose:                    Disbales automatic time zone support on device
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

logMessage "Script Started" $log_path $log_file
#####################################################################################
# Disable set time zone automatically using current location
defaults write /Library/Preferences/com.apple.timezone.auto Active -bool FALSE
#####################################################################################
# Verify results and exit accordingly
#####################################################################################
if [[ $(defaults read /Library/Preferences/com.apple.timezone.auto Active) == 0 ]]; then
  logMessage "Automatic time zone setting has been successfully disabled"
  exit 0
else
  logMessage "Failed to disable automatic time zone setting"
  exit 1
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
# exit 1 == failure to disable automatic time zone setting
# exit 2 == arrived at end of script erroneously, check script for errors
