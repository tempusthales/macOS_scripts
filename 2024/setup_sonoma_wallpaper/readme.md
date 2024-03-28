# Wallpapers for macOS Sonoma

##### PS. As usual **test**, **test**, **test** if you blow up your endpoints to mars, don't blame me. Thats on you. (Although lets admit, that would look cool...).

Apple being Apple screwed how wallpapers work in macOS Sonoma programmatically.  To say they screwed the pooch is being kind.

As such I created a two step process in order to capture wallpapers from a source folder and dump them as a base64_output.txt file that you can upload to your devices under `/var/log/lego/output` (feel free to change lego for your company name), with another process that will read that file and put the converted images to `"$HOME/Library/Application Support/com.apple.desktop.photos"` which will cause the content to be readily available on `System Settings.app > Wallpapers > Your Photos` 

# Step 1 - Convert the images to base64

1. Take the script `jpg2base64_converter.bash` and put it wherever you put your scripts on your macOS device.
2. Change line 10: `IMAGE_DIR="/PATH/TO/WALLPAPER/LOCATION"` to point to your path where your wallpapers will be. There is no limit in how many wallpapers you can convert.
3. On line 13: `IMAGE_EXTENSION="jpg"` make sure this extension matches the extension of your images. If you are using png's then just change the line to `IMAGE_EXTENSION="png"`
4. Save the script and don't forget to `chmod a+x /path/to/your/jpg2base64_converter.bash`.
5. Execute your script: `sudo ./path/to/your/jpg2base64_converter.bash`
6. Using your favorite package editor (`Composer.app` from Jamf, or `Payload-Free Package Creator.app` from the always awesome [Rich Trouton](https://derflounder.wordpress.com) which you can grab [here](https://github.com/rtrouton/Payload-Free-Package-Creator). Package the `base64_output.txt` (make sure you conserve the path `/var/log/lego/output/base64_output.txt`) --If you want to change this path you can do it on Step 2 below.

# Step 2 - Add the wallpapers to their final location

1. Take the script `addwallpaper_to_sonoma.bash` and put it wherever you put your scripts on your macOS device.
2. If you want to change the path for `/var/log/lego/output/base64_output.txt` you can do it on line 16: `OUTPUT_DIR="/var/log/lego/output"`
3. 
4. Save the script and don't forget to `chmod a+x /path/to/your/addwallpaper_to_sonoma.bash`.
5. Execute your script: `sudo ./path/to/your/addwallpaper_to_sonoma.bash`
6. To test that everything is fine and dandy open `System Settings.app > Wallpapers > Your Photos` if all worked out, you should see all your photos there.
7. Choose the wall paper you want to start with or click on the square with the circling arrows for Shuffle. --Side note: Apple doesn't let you control programatically if you want to use Shuffle... Sigh. So you need to tell your users to pick that themselves.

# How to deploy this on JAMF Pro (or Jamf Cloud)

##### I use Jamf Cloud, I'm sure if you use some other MDM if you follow the next steps you will be able to deploy it just fine.

1. Create the script `addwallpaper_to_sonoma.bash` on `Settings > Scripts > +New Script` blah blah you know this...
2. Upload your `base64_output.txt` pkg to Jamf via `Settings > Packages > +New Package` blah blah you (also should) know this...
3. Create the policy via `Computers > Policies > +New Policy` yadda yadda, etc.
4. Add your package and your script to policy, make sure the script runs AFTER the package has installed.
5. Make it available in Self Service (if you want) or not.
6. Scope it to whomever.
7. Pray it works so you don't get fired.

# Help? - Sure why not! =)
I don't plan to have a channel dedicated for this on MacAdmins Slack but if you have an account there you can find me as [Gil](https://macadmins.slack.com/team/U2M0P3VFT) or you can ping me on Discord as the one and only Tempus Thales (or tempus thales#2600).

I can help you, but again, **test**, **test**, **test** and bring your logs. No logs, no laundry.

Cheers!

###### PS If you are one of those and wants to buy me [Ko-Fi](https://ko-fi.com/tempusthales).


