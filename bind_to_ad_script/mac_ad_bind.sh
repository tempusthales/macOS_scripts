#!/bin/bash

## Script designed to join a macOS computer to AD Domain.  Script works with Filewave, JAMF Pro or Munki
## Remember to check for sanitized variables before you deploy

# Get computer name...

computerid=`/usr/sbin/scutil --get ComputerName`

# grab contents of System Preferences -> Sharing -> Computer Settings -> Info 1
# this will eventually contain building's OU so we can bind and place machine into
# the proper OU automatically.

location=`defaults read /Library/Preferences/com.apple.RemoteDesktop Text1`

# Use these credentials bind the mac to AD 
# NOTE: If using JAMF you will need to change the variables strings to $3 and $4 because JAMF Pro is S.P.E.C.I.A.L

uname=$1
pass=$2

ou="OU=NAME-OF-OU,DC=your,DC=network,DC=com"
os=`sw_vers -productVersion | awk -F "." '{print $2}'`
os=$(($os+0))
newou="$ou";
echo "****Current Serial Number****"
echo $serial
echo "****Current Name Number****"
echo $computerid
echo "****Current Location****"
echo $location
echo "--------"
echo "****Machine will be bound to following OU****"
echo $newou

if [[ "$os" -ge "7" ]] ; then
                echo "higher than 10.6"
                #10.7, 10.8, 10.9
				echo "****Removing Current Bindings****"
				dsconfigad -remove -username $uname -password $pass
				echo "Begin Binding..."
				dsconfigad -force -add "your.network.com" -alldomains enable -mobile enable -mobileconfirm disable -computer $computerid -username $uname -password $pass -domain "DC=your,DC=network,DC=com" -ou "$newou"
        else 
                echo "10.6.8 or lower"
                #10.6
				echo "****Removing Current Bindings****"
				dsconfigad -r -u $uname -p $pass		
				echo "Begin Binding..."
				dsconfigad -f -a $computerid -domain "your.domain.com" -u $uname -p $pass -ou "$newou" -mobile enable -mobileconfirm disable -alldomains enable -groups "COMPUTERGROUPHERE"
        fi

## Adding search paths
sleep 20

## Create the search paths in DS for authentication and contacts.
dscl /Search -create / SearchPolicy CSPSearchPath
dscl /Search/Contacts -create / SearchPolicy CSPSearchPath

## Add our AD domain to the search paths.
dscl /Search/Contacts -append / CSPSearchPath "Active Directory/All Domains"
dscl /Search -append / CSPSearchPath "Active Directory/All Domains"

echo "Binding Complete"

exit 0