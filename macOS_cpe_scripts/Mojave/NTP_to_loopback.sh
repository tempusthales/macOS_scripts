#!/bin/bash

#####################################################################################
# Name:                       NTP_to_loopback.sh
# Purpose:                    Restricts NTP server to loopback interface

#####################################################################################
# Establish standardized local logging logic
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

logMessage "Script starting..."

#####################################################################################
# Create /etc/ntp-restrict.conf if it does not exist
# and write restriction to loopback interface
#####################################################################################
# check if /etc/ntp-restrict.conf does not exist and remediate as needed
if [[ ! -f /etc/ntp-restrict.conf ]]; then
  logMessage "/etc/ntp-restrict.conf does not exist"
  logMessage "Creating /etc/ntp-restrict.conf and populating"
  # if not, create, set permissions/ownership
  cat > "/etc/ntp-restrict.conf" << 'EOF'
restrict lo
interface ignore wildcard
interface listen lo
EOF
  # set permissions
  chmod 644 /etc/ntp-restrict.conf
  #set ownership
  chown root:wheel /etc/ntp-restrict.conf

  # verify /etc/ntp-restrict.conf contents
  if [[ $(cat /etc/ntp-restrict.conf | grep "restrict lo") =~ "restrict lo" ]]; then
    logMessage "/etc/ntp-restrict.conf appended contents:"
    logMessage "
    $(cat /etc/ntp-restrict.conf)"
    logMessage "/etc/ntp-restrict.conf created successfully"
    logMessage "Exiting..."
    exit 0
  else
    logMessage "Failed to successfully create /etc/ntp-restrict.conf"
    logMessage "Exiting with error!"
    exit 1
  fi
else
  logMessage "/etc/ntp-restrict.conf already exists"
fi
#####################################################################################
# If /etc/ntp-restrict.conf exists, append as necessary
#####################################################################################
# check for "restrict lo" - remediate as needed
if [[ $(cat /etc/ntp-restrict.conf | grep "restrict lo") =~ "restrict lo" ]]; then
  logMessage "/etc/ntp-restrict.conf already contrains: restrict lo"
else
  # write content to /etc/ntp-restrict.conf
  echo "restrict lo" >> /etc/ntp-restrict.conf
  # verify
  if [[ $(cat /etc/ntp-restrict.conf | grep "restrict lo") =~ "restrict lo" ]]; then
    logMessage "restrict lo written to /etc/ntp-restrict.conf"
  else
    # log write error
    RLfail=1
  fi
fi

# check for "interface ignore wildcard" - remediate as needed
if [[ $(cat /etc/ntp-restrict.conf | grep "interface ignore wildcard") =~ "interface ignore wildcard" ]]; then
  logMessage "/etc/ntp-restrict.conf already contrains: interface ignore wildcard"
else
  # write content to /etc/ntp-restrict.conf
  echo "interface ignore wildcard" >> /etc/ntp-restrict.conf
  # verify
  if [[ $(cat /etc/ntp-restrict.conf | grep "interface ignore wildcard") =~ "interface ignore wildcard" ]]; then
    logMessage "interface ignore wildcard written to /etc/ntp-restrict.conf"
  else
    # log write error
    IIWCfail=1
  fi
fi

# check for "interface listen lo" - remediate as needed
if [[ $(cat /etc/ntp-restrict.conf | grep "interface listen lo") =~ "interface listen lo" ]]; then
  logMessage "/etc/ntp-restrict.conf already contrains: interface listen lo"
else
  # write content to /etc/ntp-restrict.conf
  echo "interface listen lo" >> /etc/ntp-restrict.conf
  # verify
  if [[ $(cat /etc/ntp-restrict.conf | grep "interface listen lo") =~ "interface listen lo" ]]; then
    logMessage "interface listen lo written to /etc/ntp-restrict.conf"
  else
    # log write error
    ILLfail=1
  fi
fi
#####################################################################################
# Exit with proper status based on run
#####################################################################################
# exit with proper code based on run
if [[ "$RLfail" == "" ]] && [[ "$IIWCfail" == "" ]] && [[ "$ILLfail" == "" ]]; then
  logMessage "Script completed successfully"
  logMessage "Exiting..."
  exit 0
elif [[ "$RLfail" == "1" ]] && [[ "$IIWCfail" == "" ]] && [[ "$ILLfail" == "" ]]; then
  logMessage "Exiting with error 2..."
  exit 2
elif [[ "$RLfail" == "" ]] && [[ "$IIWCfail" == "1" ]] && [[ "$ILLfail" == "" ]]; then
  logMessage "Exiting with error 3..."
  exit 3
elif [[ "$RLfail" == "" ]] && [[ "$IIWCfail" == "" ]] && [[ "$ILLfail" == "1" ]]; then
  logMessage "Exiting with error 4..."
  exit 4
elif [[ "$RLfail" == "1" ]] && [[ "$IIWCfail" == "1" ]] && [[ "$ILLfail" == "" ]]; then
  logMessage "Exiting with error 5..."
  exit 5
elif [[ "$RLfail" == "1" ]] && [[ "$IIWCfail" == "" ]] && [[ "$ILLfail" == "1" ]]; then
  logMessage "Exiting with error 6..."
  exit 6
elif [[ "$RLfail" == "" ]] && [[ "$IIWCfail" == "1" ]] && [[ "$ILLfail" == "1" ]]; then
  logMessage "Exiting with error 7..."
  exit 7
fi

#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 8

#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == failure to write complete /etc/ntp-restrict.conf
# exit 2 == failure to set "restrict lo"
# exit 3 == failure to set "interface ignore wildcard"
# exit 4 == failure to set "interface listen lo"
# exit 5 == failure to set "restrict lo" & "interface ignore wildcard"
# exit 6 == failure to set "restrict lo" & "interface listen lo"
# exit 7 == failure to set "restrict lo" & "interface ignore wildcard" & "interface listen lo"
# exit 8 == arrived at end of script erroneously, check script for errors
