# Jamf Binary Self Healing Utility
###### Powered by swiftDialog (https://github.com/swiftDialog/swiftDialog)

The Jamf Binary Self Heal utility will remotely install the Jamf Binary on computers that are unable to check-in, run policies, or update inventory.
To use it please enter the serial number(s) of the devices you wish to re-install the Jamf Binary on.  

If more than one serial please separate them with commas.  Example: serial1, serial2, serial3 etc.

### Configuration

Change the following variables to match your own.  Or you can update this from **JAMF Parameter Labels**

```
# Server connection information
# Change this to your value
URL="${4:-"https://yourjss.jamfcloud.com"}"

# Enter a local Jamf Pro user here
username=${5:-"username"}
password=${6:-"password"}

# Branding
icon="${7:-"https://i.imgur.com/CmyJTnq.png"}"

# Script Logging
# Change this to your value
scriptLog="${8:-"/var/log/com.yourcompany.jbsh.log"}"
```

### Account Permissions

Make sure the account you are going to use for this tool has the following permissions:

```
Check-In (Read)
Computers (Read)
Computer Check-in Setting (Read)
Send Computer Remote Command to Install Package (Read)
```

PS. Don't use a full fledged admin account, just use the perms above that is all you will need.

### Support
My support is limited, but if you find a bug or you have an issue, please open an issue in github and you may ping me on MacAdmins slack and provide me the issue #. No ticket, no laundry. =)

@gil at MacAdmins Slack.  https://macadmins.org 
If you find my efforts useful buy me Coffee: [https://ko-fi.com/tempusthales](https://ko-fi.com/tempusthales)
