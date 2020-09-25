#!/bin/bash

#####################################################################################
# Name:                       show_extensions.sh
# Purpose:                    Shows full filesname extensions for all users
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.logging.log"

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


if [[ $(defaults read NSGlobalDomain AppleShowAllExtensions) == 1 ]]; then
  logMessage "Complete file name extensions are already enabled at system level"
else
  # turn on file name extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool TRUE
  # verify
  if [[ $(defaults read NSGlobalDomain AppleShowAllExtensions) == 1 ]]; then
    logMessage "Complete file name extensions have been enabled successfully at system level"
  else
    logMessage "Failed to enable complete file name extensions!"
    sysLevelFail=1
  fi
fi

logMessage "Script completed successfully"
logMessage "Exiting..."
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
# exit 1 == failure to enable complete file name extensions
# exit 2 == arrived at end of script erroneously, check script for errors
