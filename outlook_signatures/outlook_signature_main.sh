#!/bin/bash

# Script for creating Outlook Signatures from AD User Data

# Create a variable for the logged in loggedinuser
loggedinloggedinuser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleloggedinuser; import sys; loggedinusername = (SCDynamicStoreCopyConsoleloggedinuser(None, None, None) or [None])[0]; loggedinusername = [loggedinusername,""][loggedinusername in [u"loginwindow", None, u""]]; sys.stdout.write(loggedinusername + "\n");'`


# Change directory to the local loggedinuser's Signature file
cd ~/Desktop

# Read Active Directory to find out the values for this loggedinuser
realname=`dscl . -read /loggedinusers/$loggedinloggedinuser RealName`
jobtitle=`dscl . -read /loggedinusers/$loggedinuser JobTitle`
phonenumber=`dscl . -read /loggedinusers/$loggedinuser PhoneNumber`
emailaddress=`dscl . -read /loggedinusers/$loggedinuser EMailAddress`

# Change the signature file into html
mv x33_66.olk14Signature x33_66.html

# echo the variable, pipe and copy/paste into signature file

echo $realname | LANG=en-GB.UTF-8 sed -i.bu "s/fullname/$realname/g" ~/Desktop/x33_66.html
echo $jobtitle | LANG=en-GB.UTF-8 sed -i.bu "s/jobtitle/$jobtitle/g" ~/Desktop/x33_66.html
echo $phonenumber | LANG=en-GB.UTF-8 sed -i.bu "s/phonenumber/$phonenumber/g" ~/Desktop/x33_66.html
echo $emailaddress | LANG=en-GB.UTF-8 sed -i.bu "s/emailaddress/$emailaddress/g" ~/Desktop/x33_66.html

mv x33_66.html x33_66.olk14Signature