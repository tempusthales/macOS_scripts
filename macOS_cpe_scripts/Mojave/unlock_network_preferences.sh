#!/bin/bash

#####################################################################################
# Name:                       unlock_network_preferences.sh
# Purpose:                    Allow modification of network preference pane as non-admin on the device
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
#####################################################################################
# Allow non-admins to modify system network preferences
#####################################################################################
logMessage "Script Started"

# change system preferences to allow user modification and write to variable
systemPreferencesNetwork=$(security authorizationdb write system.preferences.network allow 2>&1)
echo "***$systemPreferencesNetwork***"

# verify changes
if [[ "$systemPreferencesNetwork" =~ "YES (0)" ]]; then
  logMessage "User access to network system preferences allowed successfully"
else
  # track failure
  securityAuthFail=1
  logMessage "Failed to successfully set access to network system preferences!"
fi

# change system configuration to allow user modification and write to variable
systemconfigurationNetwork=$(security authorizationdb write system.services.systemconfiguration.network allow 2>&1)
if [[ "$systemconfigurationNetwork" =~ "YES (0)" ]]; then
  logMessage "User access to system configuration allowed successfully"
else
  # track failure
  securityAuthFail2=1
  logMessage "Failed to successfully set access to network system configuration!"
fi
#####################################################################################
# Verify results and exit accordingly
#####################################################################################
if [[ "$securityAuthFail" == "" ]] && [[ "$securityAuthFail1" == "" ]]; then
  logMessage "Script completed successfully. Exiting..."
  exit 0
elif [[ "$securityAuthFail" == "1" ]] && [[ "$securityAuthFail1" == "" ]]; then
  logMessage "Exiting with error 1..."
  exit 1
elif [[ "$securityAuthFail" == "0" ]] && [[ "$securityAuthFail1" == "1" ]]; then
  logMessage "Exiting with error 2..."
  exit 2
elif [[ "$securityAuthFail" == "1" ]] && [[ "$securityAuthFail1" == "1" ]]; then
  logMessage "Exiting with error 3..."
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
# exit 1 == Failed to successfully set access to network system preferences
# exit 2 == Failed to successfully set access to network system configuration
# exit 3 == Failed to successfully set access to network system preferences AND failed to successfully set access to network system configuration
# exit 4 == Arrived at end of script erroneously, check script for errors
