#!/bin/bash

#####################################################################################
# Name:                       disable_macos_autoupdates.sh
# Purpose:                    Disables macOS software updates
# Notes:                      Disbales macOS sofware updates. Pair with configuration profile
#                             to prevent end-user re-enablement
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.SWUdisable.log"

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
#####################################################################################
# Disable automatic installation of Apple SWUs
#####################################################################################
if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates) == 0 ]]; then
  logMessage "Automatic installation of Apple Software Updates already disabled"
else
  defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates -bool false
  if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates) == 0 ]]; then
    logMessage "Automatic installation of Apple Software Updates has been successfully disabled"
  else
    AutomaticallyInstallFail=1
  fi
fi
#####################################################################################
# Disable automatic checking for Apple SWUs
#####################################################################################
if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled) == 0 ]]; then
  logMessage "Automatic checking for Apple Software Updates already disabled"
else
  defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool false
  if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled) == 0 ]]; then
    logMessage "Automatic checking for Apple Software Updates has been successfully disabled"
  else
    AutomaticallyCheckFail=1
  fi
fi
#####################################################################################
# Disable automatic download of Apple SWUs
#####################################################################################
if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload) == 0 ]]; then
  logMessage "Automatic download of Apple Software Updates already disabled"
else
  defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false
  if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload) == 0 ]]; then
    logMessage "Automatic download of Apple Software Updates has been successfully disabled"
  else
    AutomaticallyDownloadFail=1
  fi
fi
#####################################################################################
# Disable automatic installtion of critical Apple SWUs
#####################################################################################
if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall) == 0 ]]; then
  logMessage "Automatic installation of critical Apple Software Updates already disabled"
else
  defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false
  if [[ $(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall) == 0 ]]; then
    logMessage "Automatic installation of critical Apple Software Updates has been successfully disabled"
  else
    CriticalUpdateFail=1
  fi
fi
#####################################################################################
# Exits and verifications
#####################################################################################
# exit with proper code based on run
if [[ "$AutomaticallyInstallFail" == "" ]] && [[ "$AutomaticallyCheckFail" == "" ]] && [[ "$AutomaticallyDownloadFail" == "" ]] && [[ "$CriticalUpdateFail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
elif [[ "$AutomaticallyInstallFail" == "1" ]] && [[ "$AutomaticallyCheckFail" == "" ]] && [[ "$AutomaticallyDownloadFail" == "" ]] && [[ "$CriticalUpdateFail" == "" ]]; then
  logMessage "Failed to disable automatic installation of Apple Software Updates"
  logMessage "Exiting with error..."
  exit 1
elif [[ "$AutomaticallyInstallFail" == "" ]] && [[ "$AutomaticallyCheckFail" == "1" ]] && [[ "$AutomaticallyDownloadFail" == "" ]] && [[ "$CriticalUpdateFail" == "" ]]; then
  logMessage "Failed to disable automatic checking for Apple Software Updates"
  logMessage "Exiting with error..."
  exit 2
elif [[ "$AutomaticallyInstallFail" == "" ]] && [[ "$AutomaticallyCheckFail" == "" ]] && [[ "$AutomaticallyDownloadFail" == "1" ]] && [[ "$CriticalUpdateFail" == "" ]]; then
  logMessage "Failed to disable automatic download of Apple Software Updates"
  logMessage "Exiting with error..."
  exit 3
elif [[ "$AutomaticallyInstallFail" == "" ]] && [[ "$AutomaticallyCheckFail" == "" ]] && [[ "$AutomaticallyDownloadFail" == "" ]] && [[ "$CriticalUpdateFail" == "1" ]]; then
  logMessage "Failed to disable automatic installation of critical Apple Software Updates"
  logMessage "Exiting with error..."
  exit 4
else
  logMessage "Multiple elements of the scripts failed to execute as intended"
  if [[ "$AutomaticallyInstallFail" == "1" ]]; then
    logMessage "Failed to disable automatic installation of Apple Software Updates"
  fi
  if [[ "$AutomaticallyCheckFail" == "1" ]]; then
    logMessage "Failed to disable automatic checking for Apple Software Updates"
  fi
  if [[ "$AutomaticallyDownloadFail" == "1" ]]; then
    logMessage "Failed to disable automatic download of Apple Software Updates"
  fi
  if [[ "$CriticalUpdateFail" == "1" ]]; then
    logMessage "Failed to disable automatic installation of critical Apple Software Updates"
  fi
  logMessage "Exiting with error..."
  exit 5
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 6
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == Failed to disable automatic installation of Apple Software Updates
# exit 2 == Failed to disable automatic checking for Apple Software Updates
# exit 3 == Failed to disable automatic download of Apple Software Updates
# exit 4 == Failed to disable automatic installation of critical Apple Software Updates
# exit 5 == failure to set multiple items, see log for specifics
# exit 6 == arrived at end of script erroneously, check script for errors
