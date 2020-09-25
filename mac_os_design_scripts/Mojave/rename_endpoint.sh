#!/bin/bash
##################################################################################################################
# Name:                       rename_endpoint.sh
# Purpose:                    Rename a mac endpoint to it's serial number
###################################################################################################################
# GLOBAL VARIABLES
###################################################################################################################
log_path="/var/log/company_name"
log_file="com.company_name.macos.system_access.log"
SerialNumber=$(ioreg -l | grep "IOPlatformSerialNumber" | cut -d ""="" -f 2 | sed -e s/[^[:alnum:]]//g)
ComputerName=$(scutil --get ComputerName)
LocalHostName=$(scutil --get LocalHostName)
# redirection stderr to stdout to prevent un-set HostName error from hitting stdout
HostName=$(scutil --get HostName 2>&1)
hostDomain=$(dsconfigad -show | awk '/Active Directory Domain/{print $NF}')
FQDN=$(echo "$SerialNumber.$hostDomain")
##################################################################################################################
# ESTABLISH STANDARDIZED LOCAL LOGGING LOGIC
##################################################################################################################
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
####################################################################################################
# Computer Name
####################################################################################################
if [[ "$ComputerName" =~ "$SerialNumber" ]]; then
    logMessage "Computer name does contain Serial Number, skipping rename..."
else
    logMessage "Computer name does not contain Serial Number, renaming computer..."
    # rename computer
    scutil --set ComputerName "$SerialNumber"
    if [[ $(scutil --get ComputerName) =~ "$SerialNumber" ]]; then
      logMessage "Computer name set successfully to $(scutil --get ComputerName)"
    else
      logMessage "Failed to set computer name!"
      cNameSetFail=1
    fi
fi
####################################################################################################
# LocalHost Name
####################################################################################################
if [[ "$LocalHostName" =~ "$SerialNumber" ]]; then
    logMessage "LocalHost name does contain Serial Number, skipping rename..."
else
    logMessage "LocalHost name does not contain Serial Number, renaming..."
    # set localHost
    scutil --set LocalHostName "$SerialNumber"
    if [[ $(scutil --get LocalHostName) =~ "$SerialNumber" ]]; then
      logMessage "LocalHost name set successfully to $(scutil --get LocalHostName)"
    else
      logMessage "Failed to set LocalHost name!"
      LHnameSetFail=1
    fi
fi
####################################################################################################
# Host Name
####################################################################################################
# check if bound to AD
if [[ $(dsconfigad -show) == "" ]]; then
  if [[ "$HostName" =~ "$(echo $SerialNumber.local)" ]]; then
      logMessage "Host name does contain Serial Number and .local suffix, skipping rename..."
  else
    # if not bound, set .local host name
    logMessage "Endpoint not bound to AD"
    scutil --set HostName "$(echo $SerialNumber.local)"
    if [[ $(scutil --get HostName) =~ "$(echo $SerialNumber.local)" ]]; then
      logMessage "Host name name set successfully to $SerialNumber.local"
    else
      logMessage "Failed to set Host name!"
      HnameSetFail=1
    fi
  fi
else
  # set host name based on bound AD domain
  if [[ "$HostName" =~ "$FQDN" ]]; then
      logMessage "Host name does contain Serial Number and AD domain suffix, skipping rename..."
  else
      logMessage "Host name does not contain Serial Number and/or AD suffix, renaming..."
      # set host name
      scutil --set HostName "$FQDN"
      if [[ $(scutil --get HostName) =~ "$FQDN" ]]; then
        logMessage "Host name name set successfully to $(scutil --get HostName)"
      else
        logMessage "Failed to set Host name!"
        HnameSetFail=1
      fi
  fi
fi
####################################################################################################
# rename SMB servername
####################################################################################################
#  rename SMB server NetBIOS name if does not match serial
if [[ $(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName) =~ "$SerialNumber" ]]; then
  logMessage "SMB server NetBIOS name already set to serial"
else
  # set SMB servername
  defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $SerialNumber
  if [[ $(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName) =~ "$SerialNumber" ]]; then
    logMessage "SMB server NetBIOS name set successfully to $(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName)"
  else
    logMessage "Failed to set SMB server NetBIOS name!"
    SMBnameSetFail=1
  fi
fi
#####################################################################################
# Exits and verifications
#####################################################################################
# exit with proper code based on run
if [[ "$cNameSetFail" == "" ]] && [[ "$LHnameSetFail" == "" ]] && [[ "$HnameSetFail" == "" ]] && [[ "$SMBnameSetFail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
elif [[ "$cNameSetFail" == "1" ]] && [[ "$LHnameSetFail" == "" ]] && [[ "$HnameSetFail" == "" ]] && [[ "$SMBnameSetFail" == "" ]]; then
  logMessage "Exiting with error 1..."
  exit 1
elif [[ "$cNameSetFail" == "" ]] && [[ "$LHnameSetFail" == "1" ]] && [[ "$HnameSetFail" == "" ]] && [[ "$SMBnameSetFail" == "" ]]; then
  logMessage "Exiting with error 2..."
  exit 2
elif [[ "$cNameSetFail" == "" ]] && [[ "$LHnameSetFail" == "" ]] && [[ "$HnameSetFail" == "1" ]] && [[ "$SMBnameSetFail" == "" ]]; then
  logMessage "Exiting with error 3..."
  exit 3
elif [[ "$cNameSetFail" == "" ]] && [[ "$LHnameSetFail" == "" ]] && [[ "$HnameSetFail" == "" ]] && [[ "$SMBnameSetFail" == "1" ]]; then
  logMessage "Exiting with error 4..."
  exit 4
else
  logMessage "Multiple elements of the scripts failed to execute as intended"
  if [[ "$cNameSetFail" == "1" ]]; then
    logMessage "Failed to set computer name"
  fi
  if [[ "$LHnameSetFail" == "1" ]]; then
    logMessage "Failed to set LocalHost name"
  fi
  if [[ "$HnameSetFail" == "1" ]]; then
    logMessage "Failed to set host name"
  fi
  if [[ "$SMBnameSetFail" == "1" ]]; then
    logMessage "Failed to set SMB NetBIOS name"
  fi
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
# exit 1 == failure to set computer name
# exit 2 == failure to set LocalHost name
# exit 3 == failure to set host name
# exit 4 == failure to set SMB NetBIOS name
# exit 5 == failure to set multiple naming items, see log for specifics
# exit 6 == arrived at end of script erroneously, check script for errors
