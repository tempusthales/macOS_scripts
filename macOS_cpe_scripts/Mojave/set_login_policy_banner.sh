#!/bin/bash
####################################################################################
# Name:                       set_login_policy_banner.sh
# Author:                      Tempus Thales
# Purpose:                    Sets login policy banner
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

logMessage "/Library/Security/PolicyBanner.rtf"
#create new /private/etc/asl.conf
cat > /Library/Security/PolicyBanner.rtf << 'EOF'
{\rtf1\ansi\ansicpg1252\cocoartf1404\cocoasubrtf460
\cocoascreenfonts1{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;\red0\green44\blue118;\red0\green0\blue255;}
\margl1440\margr1440\vieww8900\viewh9140\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\li353\fi0\ri720\pardirnatural\qc\partightenfactor0

\f0\b\fs42 \cf2 \
Please Click Accept to Agree and Logon
\fs48 \cf3 \
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\li353\fi0\ri720\pardirnatural\partightenfactor0

\b0\fs24 \cf0 \
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\li353\fi0\ri720\sl288\slmult1\pardirnatural\partightenfactor0

\fs26 \cf0 company_name group Inc. or one of its subsidiaries or their affiliates (company_namegroup) has provided this System for approved purposes only. Consistent with the company_namegroup Electronic Communications policy and other applicable policies, you are prohibited from using the System for downloading, transmitting or communicating images or text consisting of threats to the safety of persons or property, misuse of proprietary or confidential information, ethnic slurs, racial epithets, hate speech, sexually explicit material, obscenities or anything else that may be construed as inappropriate, harassing or offensive to others based on any protected category set forth in company_namegroup's Code of Conduct. All data, information and communications generated or received by you or otherwise residing upon this System are the sole property of company_namegroup and may be intercepted, stored, accessed, viewed and used by company_namegroup for any purpose. Email sent through this System and other System activities are not private and are monitored by company_namegroup.\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\li353\fi0\ri720\pardirnatural\partightenfactor0
\cf0 \
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\li353\fi0\ri720\sl288\slmult1\pardirnatural\partightenfactor0
\cf0 Your use of this System indicates your understanding of this Notice, your commitment to use the System consistent with all the applicable laws and company_namegroup policies, and your consent to company_namegroup's monitoring of your email and other System activity.}
EOF
logMessage "Setting permissions and ownership for /Library/Security/PolicyBanner.rtf"
# set permissions
chmod o+r /Library/Security/PolicyBanner.rtf

logMessage "/Library/Security/PolicyBanner.rtf was created/modified on $(ls -alh /Library/Security/PolicyBanner.rtf | awk '{print $6,$7,$8}')"

logMessage "Script complete"
logMessage "Exiting..."
exit 0
