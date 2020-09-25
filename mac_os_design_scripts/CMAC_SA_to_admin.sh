#!/bin/bash

#####################################################################################
# Name:                       system_admins_to_admin.sh
# Purpose:                    SAs to AD binding as administrators
# Notes:                      Must be run after computer is bound
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.preferences.log"

logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d::%H:%M:%S-%z) 2>&1)"
  user="$((who -m | awk '{print $1;}') 2>&1)"
  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo -e "$date_set\t$user\t${0##*/}\t$1"
  else
    # write local logs
    echo -e "$date_set\t$user\t${0##*/}\t$1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo -e "$date_set\t$user\t${0##*/}\t$1"
  fi
}

logMessage "Script Started"

#####################################################################################
# Add SA to AD binding as administrators
#####################################################################################
# check if CMAC SAs are admins and grant proper access if not
if [[ $(dsconfigad -show | grep "Allowed admin groups" | awk '{print $5}') == "SAs" ]]; then
  logMessage "SAs are already a part of the local admin group"
  logMessage "Exiting..."
  exit 0
elif [[ $(dsconfigad -show) == "" ]]; then
  logMessage "This endpoint is not bound to an AD domain!"
  logMessage "Exiting with error..."
  exit 1
else
  ADbindingOutput=$(dsconfigad -groups "CMAC_SAs" 2>&1)
  logMessage "Attempted to add SAs to local administrators group"
  logMessage "Command result: $ADbindingOutput"
  logMessage "Current AD group(s) that are have local admin privleges: $(dsconfigad -show | grep "Allowed admin groups" | awk '{print $5}')"

  # verify changes
  if [[ $(dsconfigad -show | grep "Allowed admin groups" | awk '{print $5}') == "SAs" ]]; then
    logMessage "SAs have been successfully added to the local admin group"
    logMessage "Script complete"
    logMessage "Exiting..."
    exit 0
  else
    logMessage "Failed to add SAs to the local admin group!"
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
# exit 1 == computer not bound to an AD domain
# exit 2 == failure to add SAs to the local admin group
# exit 3 == arrived at end of script erroneously, check script for errors
