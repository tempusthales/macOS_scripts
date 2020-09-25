#!/bin/bash

#####################################################################################
# Name:                       audit_flags.sh
# Purpose:                    Configure OpenBSM security auditing flags on the device
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
#####################################################################################
# Set OpenBSM audit flags
#####################################################################################
# verify that /etc/security/audit_control exists and make changes if so
if [[ -f /etc/security/audit_control ]]; then
  logMessage "Script starting to set OpenBSM auditing flags..."
  # set variable defining OpenBSM audit flags
  flags="lo,aa,ad,fd,fm,-all"
  # replace audit-flag-defining line in /etc/security/audit_control
  sed -ie 's/^flags\(.*\)/flags:'$flags'/' /etc/security/audit_control
  # read current audit flags value line in /etc/security/audit_control as set by $flags
  OpenBSMflags=$(grep "flags:$flags" /etc/security/audit_control)
  #####################################################################################
  # Verifications and log output
  #####################################################################################
  # verify contents of flags line in /etc/security/audit_control and log appropriately
  if [[ "$OpenBSMflags" != "" ]]; then
    logMessage "OpenBSM audit flags in /etc/security/audit_control set $OpenBSMflags"
    logMessage "OpenBSM auditing flags script completed successfully"
    exit 0
  else
    logMessage "OpenBSM audit flags setting failure!"
    logMessage "Current audit flags set - $(grep 'flags:' /etc/security/audit_control | head -1)"
    logMessage "Exiting with error..."
    exit 2
  fi
else
  logMessage "/etc/security/audit_control does not exist!"
  logMessage "Exiting with error!"
  exit 1
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
# exit 1 == /etc/security/audit_control does not exist
# exit 2 == failure to set OpenBSM flags as defined
# exit 3 == arrived at end of script erroneously, check script for errors
