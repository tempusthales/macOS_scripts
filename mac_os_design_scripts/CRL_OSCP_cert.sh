#!/bin/bash

#####################################################################################
# Name:                       CRL_OSCP_cert.sh
# Purpose:                    Enables CRL and OSCP checking
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

logMessage "Script Started"

#####################################################################################
# Enable CRL certificate checking
#####################################################################################
# check current status of CRL certificate checking
if [[ $(defaults read com.apple.security.revocation CRLStyle) =~ "RequireIfPresent" ]]; then
  logMessage "CRL certificate checking already required"
else
  # enable CRL certificate checking
  defaults write com.apple.security.revocation CRLStyle -string RequireIfPresent
  # verify change
  if [[ $(defaults read com.apple.security.revocation CRLStyle) =~ "RequireIfPresent" ]]; then
    logMessage "CRL certificate checking set to: RequireIfPresent"
  else
    logMessage "Failed to properly set CRL certificate checking!"
    CRLsetFail=1
  fi
fi
#####################################################################################
# Enable OSCP certificate checking
#####################################################################################
# check current status of OSCP certificate checking
if [[ $(defaults read com.apple.security.revocation OCSPStyle) =~ "RequireIfPresent" ]]; then
  logMessage "OSCP certificate checking already required"
else
  # enable OSCP certificate checking
  defaults write com.apple.security.revocation OCSPStyle -string RequireIfPresent
  # verify change
  if [[ $(defaults read com.apple.security.revocation OCSPStyle) =~ "RequireIfPresent" ]]; then
    logMessage "OSCP certificate checking set to: RequireIfPresent"
  else
    logMessage "Failed to properly set OSCP certificate checking!"
    OSCPsetFail=1
  fi
fi
# exit with proper code based on run
if [[ "$CRLsetFail" == "" ]] && [[ "$OSCPsetFail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
elif [[ "$CRLsetFail" == "1" ]] && [[ "$OSCPsetFail" == "" ]]; then
  logMessage "Exiting with error 1..."
  exit 1
elif [[ "$CRLsetFail" == "" ]] && [[ "$OSCPsetFail" == "1" ]]; then
  logMessage "Exiting with error 2..."
  exit 2
elif [[ "$CRLsetFail" == "1" ]] && [[ "$OSCPsetFail" == "1" ]]; then
  logMessage "Exiting with error 3..."
  exit 3
fi

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
# exit 1 == failure to set CRL certificate checking
# exit 2 == failure to set OSCP certificate checking
# exit 3 == failure to set CRL & OSCP certificate checking
# exit 4 == arrived at end of script erroneously, check script for errors
