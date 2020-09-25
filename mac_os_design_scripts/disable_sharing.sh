#!/bin/bash

#####################################################################################
# Name:                       disable_sharing.sh
# Purpose:                    Disables sharing servies for device
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.preferences.log"

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
# Disable Remote Apple Events
#####################################################################################
# disable remote Apple events and set to variable
RemoteEventsStatus=$(systemsetup -setremoteappleevents off 2>&1)

# test if remote Apple events were disbabled and log filure variable if not
if [[ "$RemoteEventsStatus" =~ "off" ]]; then
  logMessage "Remote Apple Events disabled successfully"
else
  logMessage "Failed to disable Remote Apple Events"
  RAEfail=1
fi
#####################################################################################
# Disable screeen sharing
#####################################################################################
# Disables screen sharing if running
screenshareEnabled=$(launchctl list | grep "screensharing")

# test and enforce
if [[ "$screenshareEnabled" == "" ]]; then
  logMessage "Screen sharing not currently running"
else
  # unload screen sharing launch daemon
  launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
  # wait for termination
  sleep 2
  # verify
  if [[ $(launchctl list | grep "screensharing") == "" ]]; then
    logMessage "Screensharing disabled successfully"
  else
    logMessage "Failed to disable screen sharing!"
    SSfail=1
  fi
fi
#####################################################################################
# Disable printer sharing
#####################################################################################
# see if printers are shared
printerSharing=$(cupsctl | grep "_share_printers=" | sed 's/_share_printers=//g')

# test and enforce
if [[ "$printerSharing" == 1 ]]; then
  cupsctl --no-share-printers
  lpadmin -p ALL -o printer-is-shared="False"
  logMessage "Printer sharing has been disabled"
  # wait for termination
  sleep 2
  # verify disablement
  if [[ $(cupsctl | grep "_share_printers=" | sed 's/_share_printers=//g') == "" ]]; then
    logMessage "Screensharing disabled successfully"
  else
    logMessage "Failed to disable screen sharing!"
    PSfail=1
  fi
else
  logMessage "Printer sharing was already disabled"
fi
#####################################################################################
# Disable local AFP server
#####################################################################################
# disables AFP file sharing if running
AFPstatus=$(launchctl list | grep "AppleFileServer")

# test and enforce
if [[ "$afpEnabled" = "" ]]; then
  logMessage "Local AFP server not running"
else
  # unload AFP server
  launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
  # wait for termination
  sleep 2
  # verify disablement
  if [[ $(launchctl list | grep "AppleFileServer") == "" ]]; then
    logMessage "Local AFP server disabled successfully"
  else
    logMessage "Failed to disable local AFP server!"
    AFPfail=1
  fi
fi
#####################################################################################
# Disable local SMB server
#####################################################################################
# disables AFP file sharing if running
SMBstatus=$(launchctl list | grep "smbd")

# test and enforce
if [[ "$SMBstatus" = "" ]]; then
  logMessage "Local SMB server not running"
else
  # unload SMB server
  launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist
  # wait for termination
  sleep 2
  # verify disablement
  if [[ $(launchctl list | grep "smbd") == "" ]]; then
    logMessage "Local SMB server disabled successfully"
  else
    logMessage "Failed to disable local SMB server!"
    SMBfail=1
  fi
fi
#####################################################################################
# Disable Apple Remote Desktop remote management
#####################################################################################
# Disables Remote Management
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off
logMessage "Remote Management disabled"
#####################################################################################
# Exits and verifications
#####################################################################################
# exit with proper code based on run
if [[ "$RAEfail" == "" ]] && [[ "$SSfail" == "" ]] && [[ "$PSfail" == "" ]] && [[ "$AFPfail" == "" ]] && [[ "$SMBfail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
elif [[ "$RAEfail" == "1" ]] && [[ "$SSfail" == "" ]] && [[ "$PSfail" == "" ]] && [[ "$AFPfail" == "" ]] && [[ "$SMBfail" == "" ]]; then
  logMessage "Exiting with error 1..."
  exit 1
elif [[ "$RAEfail" == "" ]] && [[ "$SSfail" == "1" ]] && [[ "$PSfail" == "" ]] && [[ "$AFPfail" == "" ]] && [[ "$SMBfail" == "" ]]; then
  logMessage "Exiting with error 2..."
  exit 2
elif [[ "$RAEfail" == "" ]] && [[ "$SSfail" == "" ]] && [[ "$PSfail" == "1" ]] && [[ "$AFPfail" == "" ]] && [[ "$SMBfail" == "" ]]; then
  logMessage "Exiting with error 3..."
  exit 3
elif [[ "$RAEfail" == "" ]] && [[ "$SSfail" == "" ]] && [[ "$PSfail" == "" ]] && [[ "$AFPfail" == "1" ]] && [[ "$SMBfail" == "" ]]; then
  logMessage "Exiting with error 4..."
  exit 4
elif [[ "$RAEfail" == "" ]] && [[ "$SSfail" == "" ]] && [[ "$PSfail" == "" ]] && [[ "$AFPfail" == "" ]] && [[ "$SMBfail" == "1" ]]; then
  logMessage "Exiting with error 5..."
  exit 5
else
  logMessage "Multiple elements of the scripts failed to execute as intended"
  if [[ "$RAEfail" == "1" ]]; then
    logMessage "Failed to disable remote Apple events"
  fi
  if [[ "$SSfail" == "1" ]]; then
    logMessage "Failed to disable screen sharing"
  fi
  if [[ "$PSfail" == "1" ]]; then
    logMessage "Failed to disable printer sharing"
  fi
  if [[ "$AFPfail" == "1" ]]; then
    logMessage "Failed to disable local AFP server"
  fi
  if [[ "$SMBfail" == "1" ]]; then
    logMessage "Failed to disable local SMB server"
  fi
  exit 6
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 7

#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == failure to disable remote Apple events
# exit 2 == failure to disable screen sharing
# exit 3 == failure to disable printer sharing
# exit 4 == failure to disable local AFP server
# exit 5 == failure to disable local SMB server
# exit 6 == failure to disable multiple items, see log for specifics
# exit 7 == arrived at end of script erroneously, check script for errors
