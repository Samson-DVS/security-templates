#!/bin/bash
# Author: Visahl Samson David Selvam (visahlsamson@gmail.com)
# Note: Ensure brew is installed and up to date. Adjust programs and settings as needed for macOS.

# Set server timezone to your preferred timezone (example: Asia/Kolkata)
sudo systemsetup -settimezone "Asia/Kolkata"

# Log file path
LOG_FILE="/var/log/setup_mac.log"

# Function to log messages to file
log_file() {
    local timestamp=$(date +"%d:%b:%Y, %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Create log file and set permissions
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

##########################
# SSH Configuration
##########################

log_file "Configuring SSH..."

# Disable root login via SSH (ensure root login is already disabled by default on macOS)
sudo sed -i '' 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Change SSH port to 4450 (replace 4450 with your preferred port)
sudo sed -i '' 's/#Port 22/Port 4450/' /etc/ssh/sshd_config
sudo systemsetup -f -setremotelogin on
sudo launchctl stop com.openssh.sshd
sudo launchctl start com.openssh.sshd

log_file "SSH configuration completed."

##########################
# System Security
##########################

log_file "Configuring system security..."

# Enable firewall (macOS application firewall)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode to prevent system from responding to probing
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Install Homebrew (if not already installed)
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Fail2Ban alternative (crowdsec or SSHGuard is recommended for macOS)
brew install sshguard
sudo brew services start sshguard

# Enable automatic security updates
sudo softwareupdate --schedule on

log_file "System security configuration completed."

##########################
# Firewall Configuration
##########################

log_file "Configuring firewall..."

# Set up PF (Packet Filter) rules
sudo cp /etc/pf.conf /etc/pf.conf.backup
sudo echo "block in on en0 from any to any port 22" | sudo tee -a /etc/pf.conf
sudo pfctl -e -f /etc/pf.conf

log_file "Firewall configuration completed."

# Update all software
softwareupdate --all --install --restart

# Set Singapore based timezone
sudo systemsetup -settimezone "Asia/Singapore"

log_file "Setup complete! Please check the log file ($LOG_FILE) for any errors or warnings."

# Reboot the system to apply all changes
sudo reboot
