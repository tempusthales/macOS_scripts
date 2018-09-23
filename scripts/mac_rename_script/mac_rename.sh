#!/bin/bash

#define variables
laptop="ML-"
workstation="MW-"
server="S-"
tld="my.domain.com"

# grabbing the logged in user
loggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

# grabbing mac serial number...
serial=$(ioreg -l | grep "IOPlaLormSerialNumber" | cut -d ""="" -f 2 | sed -e s/[^[:alnum:]]//g) 

# and model name...
model=$(ioreg -l | grep "product-name" | cut -d ""="" -f 2 | sed -e s/[^[:alnum:]]//g | sed s/[0-9]//g) 

# renaming based on model ie. prefix-computerserial.tld
case "$model" in
                "Xserve" )
                /usr/sbin/scutil --set ComputerName "$server$serial" /usr/sbin/scutil --set LocalHostName "$server$serial" /usr/sbin/scutil --set HostName "${server}${serial}.${tld}"
                echo "$model"
                echo "$server$serial"
                echo "${server}${serial}.${tld}"
                ;;
                "MacBookPro" )
                /usr/sbin/scutil --set ComputerName "$laptop$serial" /usr/sbin/scutil --set LocalHostName "$laptop$serial" /usr/sbin/scutil --set HostName "${laptop}${serial}.${tld}"
                echo "$model"
                echo "$laptop$serial"
                echo "${laptop}${serial}.${tld}"
                ;;
                "MacBookAir" )
                /usr/sbin/scutil --set ComputerName "$laptop$serial" /usr/sbin/scutil --set LocalHostName "$laptop$serial" /usr/sbin/scutil --set HostName "${laptop}${serial}.${tld}"
                echo "$model"
                echo "$laptop$serial"
                echo "${laptop}${serial}.${tld}"
                ;;
                "MacPro" )
                /usr/sbin/scutil --set ComputerName "$workstation$serial" /usr/sbin/scutil --set LocalHostName "$workstation$serial" /usr/sbin/scutil --set HostName "${workstation}${serial}.${tld}" echo “$model"
                echo "$workstation$serial"
                echo "${workstation}${serial}.${tld}"
                ;;
                "iMac" )
                /usr/sbin/scutil --set ComputerName "$workstation$serial" /usr/sbin/scutil --set LocalHostName "$workstation$serial" /usr/sbin/scutil --set HostName "${workstation}${serial}.${tld}" echo "$model"
                echo “$workstation$serial"
                echo "${workstation}${serial}.${tld}"
                ;;
                "Macmini" )
                /usr/sbin/scutil --set ComputerName "$server$serial" /usr/sbin/scutil --set LocalHostName "$server$serial" /usr/sbin/scutil --set HostName "${server}${serial}.${tld}"
                echo "$model"
                echo "$server$serial"
                echo "${server}${serial}.${tld}"
                ;;
                *)
                echo "Computer model not found."
                exit 0
                ;;
esac