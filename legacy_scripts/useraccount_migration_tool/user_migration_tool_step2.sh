#!/bin/bash
## Script migrated the user folder for a user account in and old system, to the new system
## Successful Exit code 0, else Exit code is 1 (bad usage),2,3,4,5,6

## This script REQUIRES SSHPass to function correctly.  Download SSHPass from https://sourceforge.net/projects/sshpass/files/sshpass/1.06/sshpass-1.06.tar.gz/download
## Extract it and cd into directory
## ./configure
## sudo make install
#
## Once created redistribute to all mac's in your environment.  Add to /usr/local/sbin 

## Clear Screen
reset

## Assume all OK
ERROR=0                              

## Set Text Bold
bold=$(tput bold)

## Set Text Normal
normal=$(tput sgr0)       

## (Optional) Uncomment if you use Slack in your Environment
## Send any alerts or Errors to Slack
## slackhook='https://hooks.slack.com/services/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'
## logfile='file.log'

## Define which user is logged in
loggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

## Define which is the correct home folder
loggedInUserHome=$(/usr/bin/dscl . -read "/Users/$loggedInUser" NFSHomeDirectory | /usr/bin/awk '{print $NF}')

## Define New Computer IP Address
ethernetport=$(awk '/inet / && $2 != "127.0.0.1"{print $2}' <(ifconfig))

## Gather which macOS Endpoint we are connecting to 
echo Username: ${bold}$loggedInUser${normal}
read -p "${bold}$loggedInUser${normal}'s host to connect to? (0.0.0.0) " IPaddress
read -s -p "Enter password for ${bold}$loggedInUser${normal}: " RSYNC_PASSWORD
echo " "
echo The Username being migrated is ${bold}$loggedInUser${normal}, the home folder is ${bold}$loggedInUserHome${normal} and his host is ${bold}$IPaddress${normal}
echo " "
read -p "Are you sure you want to continue? <y/N>: " prompt
echo " "
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]

then

## Tell the Mac to hold its breath and not go to sleep
pmset noidle &

## Begin Migration
set -e 
slack () {
sshpass -p $RSYNC_PASSWORD rsync -aE --info=progress2 --stats --human-readable --delete $loggedInUser@$IPaddress:"$loggedInUserHome" "$loggedInUserHome/Desktop/Old_$loggedInUser" | pv -les $(df -i $loggedInUser@$IPaddress:"$loggedInUserHome" | perl -ane 'print $F[2] if $F[5] =~ m:^/:') >/dev/nul| pv -les $(df -i /source | perl -ane 'print $F[2] if $F[5] =~ m:^/:') >/dev/nul
}

trap "slack "${logfile}' '${slackhook}'" 0

chflags nohidden "$loggedInUserHome/Desktop/Old_$loggedInUser/Old_Library"
echo -ne '\007'
echo -ne '\007'

else
  echo You chose poorly, quitting.

fi
# Success | Exit code 0
  logmsg "[info] successful account migrated: $loggedInUser in $loggedInUserHome on $IPaddress to $loggedInUserHome in $ethernetport
  exit 0
