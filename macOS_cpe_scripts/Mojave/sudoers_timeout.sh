#!/bin/bash
####################################################################################
# Name:                       sudoers_timeout.sh
# Author:                     Tempus Thales
# Purpose:                    Require authentication immediately after using sudo (instant timeout)
####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.security.log"

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
# Write /private/etc/sudoers.d/defaults_timestamp_timeout
#####################################################################################
# create /private/etc/sudoers.d if it does not exist and set permissions if it does not exist
if [[ ! -d /private/etc/sudoers.d/ ]]; then
  logMessage "Creating /private/etc/sudoers.d/"
  mkdir -p /private/etc/sudoers.d/
  logMessage "Setting permissions and ownership for /private/etc/sudoers.d/"
  # set permissions
  chmod 755 /private/etc/sudoers.d/
  #set ownership
  chown root:wheel /private/etc/sudoers.d/
fi

logMessage "Writing /private/etc/sudoers.d/defaults_timestamp_timeout (all sudo invocations require authentication)"
#create new /private/etc/asl.conf
cat > /private/etc/sudoers.d/defaults_timestamp_timeout << 'EOF'
Defaults timestamp_timeout=0
EOF
logMessage "Setting permissions and ownership for /private/etc/sudoers.d/defaults_timestamp_timeout"
# set permissions
chmod 600 /private/etc/sudoers.d/defaults_timestamp_timeout
#set ownership
chown root:wheel /private/etc/sudoers.d/defaults_timestamp_timeout

logMessage "/private/etc/sudoers.d/defaults_timestamp_timeout was created/modified on $(ls -alh /private/etc/sudoers.d/defaults_timestamp_timeout | awk '{print $6,$7,$8}')"

logMessage "Script complete"
logMessage "Exiting..."
exit 0
