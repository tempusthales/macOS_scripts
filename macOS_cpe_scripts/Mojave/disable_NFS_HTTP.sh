#!/bin/bash

#####################################################################################
# Name:                       disable_NFS_HTTP.sh
# Purpose:                    Disables server abilities on device
#####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.network.log"

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

#####################################################################################
# NFS server
#####################################################################################
# check if NFS launch damemon is NFSrunning
NFSrunning=$(launchctl list | grep "com.apple.nfsd")

# permanently disable NFS server if running and remove /etc/exports if it exists
if [[ "$NFSrunning" != "" ]]; then
  logMessage "NFS services detected, terminating and disabling"
  # stop NFSD
  stopNFSD=$(nfsd stop 2>&1)
  logMessage "Result of nfsd stop: $stopNFSD"
  #unload com.apple.nfsd
  launchctl unload -w /System/Library/LaunchDaemons/com.apple.nfsd.plist
fi

# disable NFSD
disableNFSD=$(nfsd disable 2>&1)

# check NFSD disablement
if [[ "$disableNFSD" =~ "already disabled" ]]; then
  logMessage "NFSD successfully disabled."
else
  logMessage "NFSD disablement failure!"
  #  create error state placeholder for NFSD disablemnent failure
  NFSDerror=1
fi

# delete if it exists
if [[ -f /etc/exports ]]; then
  # delete /etc/exports
  deleteExports=$(rm -f /etc/exports 2>&1)
  if [[ -f /etc/exports ]]; then
    logMessage "Failed to delete /etc/exports - $deleteExports"
  else
    logMessage "/etc/exports deleted"
  fi
fi
#####################################################################################
# HTTP server
#####################################################################################
# Stop HTTP server if running
httpRunning=$(launchctl list | grep "org.apache.httpd")
# set varaible for HTTP server status
apacheDaemon=$(defaults read /System/Library/LaunchDaemons/org.apache.httpd Disabled)

if [[ "$httpRunning" == "" ]]; then
  logMessage "HTTP daemon not loaded"
else
  # stop HTTP server and store output
  stopApache=$(apachectl stop 2>&1)
  # disable the LaunchDaemon from loading in the future
  if [[ $(launchctl unload -w "/System/Library/LaunchDaemons/org.apache.httpd.plist" 2>&1) =~ "Could not find specified service" ]]; then
    logMessage "Permanent stopped org.apache.httpd daemon from loading in the future"
  else
    logMessage "Output of org.apache.httpd unload: $(launchctl unload -w "/System/Library/LaunchDaemons/org.apache.httpd.plist" 2>&1)"
  fi

  # write line org.apache.httpd.plist to disable permanently if not already
  if [[ "$apacheDaemon" != 1 ]]; then
    defaults write /System/Library/LaunchDaemons/org.apache.httpd.plist Disabled -bool true
    # see if HTTP server status reads disabled again
    apacheDaemon=$(defaults read /System/Library/LaunchDaemons/org.apache.httpd Disabled)
  fi
fi
#####################################################################################
# Verify and exit
#####################################################################################
if [[ "$stopApache" == "" ]] && [[ "$apacheDaemon" == 1 ]] && [[ "$NFSDerror" == "" ]]; then
  logMessage "HTTP server stopped and Apache LaunchDaemon disabled"
  logMessage "Script completed successfully"
  exit 0
elif [[ "$stopApache" == "" ]] && [[ "$apacheDaemon" == 1 ]] && [[ "$NFSDerror" == "1" ]]; then
  logMessage "HTTP server stopped and Apache LaunchDaemon disabled but NFS was not disabled!"
  logMessage "Exiting with error..."
  exit 1
else
  logMessage "Apache stop status - $stopApache"
  logMessage "Apache daemon disable (1 if successful) state - $apacheDaemon"
  logMessage "Error encountered"
  logMessage "Exiting..."
  exit 2
fi
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
echo "Erroneously arrived at end of script..."
logMessage "Erroneously arrived at end of script..."
exit 3
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == NFS disablement failure
# exit 2 == failure to stop HTTP server, investigate
# exit 3 == arrived at end of script erroneously, check script for errors
