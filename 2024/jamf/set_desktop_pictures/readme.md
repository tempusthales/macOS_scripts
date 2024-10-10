# Read Me

The script leverages [Desktoppr](https://github.com/scriptingosx/desktoppr), a tool written by Armin Brigel (@scriptingosx on MacAdmins.org Slack) to setup the wallpaper on the desktop.

The default path to the Desktop Pictures is set to `/Users/${loggedInUser}/Library/Application Support/com.apple.desktop.photos`, because by placing your Desktop Pictures on this location will make them appear on the top of the System Preferences > Wallpaper screen under Your Photos.

Currently Apple (in their brilliance) have not created a way to rotate pictures programatically so the picture rotation is stuck at the default 30 mins with no way to change it.

However if you wish to use a different path, you can, just point the variable on line 13 to the path that you wish to use.

If you have questions join MacAdmins Slack on https://macadmins.org and @gil 
