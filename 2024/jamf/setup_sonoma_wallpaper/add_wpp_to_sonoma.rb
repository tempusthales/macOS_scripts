# Author: Tempus Thales
# Date: 2024-05-07
# Version: 1.0
# Description: Add wallpapers to macOS Sonoma
# ShellChecking done with Grimoire GPT - https://chat.openai.com/g/g-n7Rs0IK86-grimoire

require 'fileutils'
require 'open-uri'

# Function to get the logged-in user's name
def get_logged_in_user
  `echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }'`.strip
end

# Define the log file path with a timestamp globally
$log_file = "/var/log/company1/com.company.de.wallpapersetup-#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.log"

# Function to update the script log
def update_script_log(message)
  File.open($log_file, 'a') { |file| file.puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{message}" }
end

# Ensure the log file directory exists and create the log file
FileUtils.mkdir_p(File.dirname($log_file))
unless File.exist?($log_file)
  begin
    FileUtils.touch($log_file)
  rescue StandardError => e
    puts "Failed to create log file: #{e.message}. Exiting."
    update_script_log("Failed to create log file: #{e.message}.")
    exit 2
  end
end

# Log initial message
update_script_log("Script started.")

# Check for desktoppr installation and install it if not present
def ensure_desktoppr_installed
  desktoppr_path = '/usr/local/bin/desktoppr'
  unless File.executable?(desktoppr_path)
    update_script_log("desktoppr not found, downloading and installing...")
    system('curl -L https://github.com/scriptingosx/desktoppr/releases/download/v0.4/desktoppr-0.4.pkg -o /tmp/desktoppr-0.4.pkg')
    system('sudo installer -pkg /tmp/desktoppr-0.4.pkg -target /')
  end
  desktoppr_path
end

# Define the source and destination directories
source_dir = '/var/log/company/wallpapers'
logged_in_user = get_logged_in_user
destination_dir = "/Users/#{logged_in_user}/Library/Application Support/com.apple.desktop.photos"

# Ensure desktoppr is installed
desktoppr = ensure_desktoppr_installed

# Create the destination directory if it doesn't exist
Dir.mkdir(destination_dir) unless Dir.exist?(destination_dir)

# Copy files and handle spaces in paths
Dir.glob(File.join(source_dir, '*')).each do |source_file|
  filename = File.basename(source_file)
  next if filename == '.DS_Store'  # Skip .DS_Store files
  destination_file = File.join(destination_dir, filename)
  
  # Copy the file from source to destination
  begin
    FileUtils.cp(source_file, destination_file)
    update_script_log("Copied #{filename} to #{destination_dir}")
  rescue Errno::EACCES => e
    update_script_log("Permission denied when copying #{filename}: #{e.message}")
    exit 3
  end
end

# Check macOS build version for correct desktoppr command
build_version = `sw_vers -buildVersion`.strip.to_i
user_id = `id -u #{logged_in_user}`.strip
wallpaper_file = File.join(destination_dir, 'image_8.jpg')  # Specify your wallpaper file

# Ensure the path is quoted to handle spaces
quoted_wallpaper_path = wallpaper_file.inspect

# Apply the wallpaper using desktoppr
if logged_in_user != 'loginwindow' && File.exist?(wallpaper_file)
  if build_version > 21
    command = "sudo -u #{logged_in_user} launchctl asuser #{user_id} #{desktoppr} #{quoted_wallpaper_path}"
  else
    command = "launchctl asuser #{user_id} #{desktoppr} #{quoted_wallpaper_path}"
  end
  if system(command)
    system('killall WallpaperAgent')
    update_script_log("WallpaperAgent restarted to apply new settings.")
    update_script_log("Operation completed. New wallpapers are ready for selection from System Preferences.")
    exit 0
  else
    update_script_log("Failed to set the wallpaper.")
    exit 4
  end
else
  update_script_log("No user logged in, no desktop set or file does not exist.")
  exit 1
end

# Exit Codes Comment
# Exit Code 0: Success
# Exit Code 1: No user logged in, or wallpaper file does not exist
# Exit Code 2: Log file could not be created
# Exit Code 3: Permission denied when copying files
# Exit Code 4: Failed to set the wallpaper
