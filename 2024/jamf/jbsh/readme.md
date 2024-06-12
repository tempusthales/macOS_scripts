# Jamf Binary Self Healing Utility
###### Powered by swiftDialog (https://github.com/swiftDialog/swiftDialog)

The Jamf Binary Self Heal utility will remotely install the Jamf Binary on computers that are unable to check-in, run policies, or update inventory.
To use it please enter the serial number(s) of the devices you wish to re-install the Jamf Binary on.  

If more than one serial please separate them with commas.  Example: serial1, serial2, serial3 etc.

### Special thanks to Bart and swiftDialog!
* To the awesome [Bart Reardon](https://github.com/bartreardon) for making [swiftDialog](https://github.com/swiftDialog/swiftDialog), an open-source utility written in SwiftUI — that displays a popup dialog which can include content-rich messages for your end-users.
```
dialog --icon "SF=steeringwheel" --title "About swiftDialog" --message "**An open source admin utility app for macOS 13+**  \n\nWritten in SwiftUI, swiftDialog displays the content to your users in a modern UI with support for markdown, images, videos and much more …  \n\n\![Car](https://pngimg.com/uploads/tesla_car/tesla_car_PNG43.png)" --height 600 --infotext --moveable
```

![Car](https://i.imgur.com/TLDWlZS.png)

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

* Please report bugs and submit feature requests on [GitHub](https://github.com/tempusthales/macOS_scripts/issues).
* Best-effort support for this tool is offered on the [Mac Admins Slack](https://macadmins.org/) (free; registration required.) Just @gil.

### Feature Requests

Submit feature requests on [GitHub](https://github.com/tempusthales/macOS_scripts/issues).

> Please note that while all requests are welcome, finding available cycles to custom-code a feature I won’t use in my production environment is always challenging.

If you find my efforts useful buy me Coffee: [https://ko-fi.com/tempusthales](https://ko-fi.com/tempusthales)
