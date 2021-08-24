#!/bin/sh

# Script for creating Outlook Signatures from AD User Data

# Create a variable for the logged in loggedinuser
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Change directory to the local loggedinuser's Signature file
cd ~/Desktop

# Read Active Directory to find out the values for this loggedinuser
realname=`dscl . -read /loggedinusers/$currentUser RealName`
jobtitle=`dscl . -read /loggedinusers/$currentUser JobTitle`
phonenumber=`dscl . -read /loggedinusers/$currentUser PhoneNumber`
emailaddress=`dscl . -read /loggedinusers/$currentUser EMailAddress`

# Change the signature file into html
mv x33_66.olk14Signature x33_66.html

# echo the variable, pipe and copy/paste into signature file

echo $realname | LANG=en-GB.UTF-8 sed -i.bu "s/fullname/$realname/g" ~/Desktop/x33_66.html
echo $jobtitle | LANG=en-GB.UTF-8 sed -i.bu "s/jobtitle/$jobtitle/g" ~/Desktop/x33_66.html
echo $phonenumber | LANG=en-GB.UTF-8 sed -i.bu "s/phonenumber/$phonenumber/g" ~/Desktop/x33_66.html
echo $emailaddress | LANG=en-GB.UTF-8 sed -i.bu "s/emailaddress/$emailaddress/g" ~/Desktop/x33_66.html

mv x33_66.html x33_66.olk14Signature
