#!/bin/bash
##################################################################################################################
# Name:                       disable_IPv6.sh
# Purpose:                    Disables IPv6 from all network interfaces
########################################################################################################
# GLOBAL VARIABLES
###################################################################################################################
log_path="/var/log/company_name"
log_file="com.company_name.macos.disable_ipv6.log"
network_devices=$(networksetup -listallnetworkservices)
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
# Disable IPv6 for all network devices
####################################################################################################
# Detects all network hardware & creates services for all installed network hardware
if [[ "$network_devices" == "" ]]; then
  logMessage "No network devices found, exiting script with error"
  exit 1
fi

# set field seperator to a return
IFS=$'\n'

#Loops through the list of network services
for i in $(/usr/sbin/networksetup -listallnetworkservices | tail +2 ); do
  # Turn off ipv6 on each device
  /usr/sbin/networksetup -setv6off "$i" off
  logMessage "Turned off IPv6 for interface: $i"
done

# unset IFS
unset IFS

logMessage "IPv6 for all detected interfaces turned off"
logMessage "Script Finished"
exit 0
##################################################################################################################
# ERRONEOUS COMPLETION - IF THE SCRIPT PROCEEDS HERE, CHECK RECENT CODING CHANGES FOR ERRORS
##################################################################################################################
logMessage "Erroneously arrived at end of script..."
exit 2
##################################################################################################################
# Exit codes
##################################################################################################################
# exit 0 == successful run
# exit 1 == No network devices found on the system.
# exit 2 == arrived at end of script erroneously, check script for errors
##################################################################################################################
