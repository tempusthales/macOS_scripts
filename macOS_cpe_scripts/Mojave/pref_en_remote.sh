#!/bin/bash
##################################################################################################################
# Name:                       ccb_pref_en_remote.sh
# Author:                      Tempus Thales
# Purpose:                    Enables Remote Access
###################################################################################################################
# GLOBAL VARIABLES
###################################################################################################################
log_path="/var/log/company_name"
log_file="com.company_name.remote.access.log"

##################################################################################################################
# ACQUIRE VARIABLES
##################################################################################################################
currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
currentUserHome=$(dscl . -read /Users/$currentUser NFSHomeDirectory | cut -d " " -f 2)
kickstart="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart";

##################################################################################################################
# ESTABLISH STANDARDIZED LOCAL LOGGING LOGIC
##################################################################################################################

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

logMessage "Script Started"
##################################################################################################################
# SCRIPT EXECUTION
##################################################################################################################
#Enable Remote Assistance
$kickstart -activate -configure -access -off -setreqperm -reqperm yes -restart -agent
logMessage "Script completed"
exitFail=0

##################################################################################################################
# ERROR CHECKING AND VERIFICATION - EXIT WITH PROPER CODE BASED ON RUN
##################################################################################################################

if [[ "$exitFail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
fi

##################################################################################################################
# ERRONEOUS COMPLETION - IF THE SCRIPT PROCEEDS HERE, CHECK RECENT CODING CHANGES FOR ERRORS
##################################################################################################################

logMessage "Erroneously arrived at end of script..."
exit 7

##################################################################################################################
# Exit codes
##################################################################################################################
# exit 0 == successful run
# exit 1 == script has already run in this system.
# exit 2 == dockutil is not installed. Skipping dock configuration.
# exit 3 == arrived at end of script erroneously, check script for errors
##################################################################################################################
