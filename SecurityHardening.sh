#!/bin/bash
# Author: Visahl Samson David Selvam (visahlsamson@gmail.com)

# Set server timezone to India time, but you can choose the timezone you require
sudo timedatectl set-timezone Asia/Kolkata

# Log file path
LOG_FILE="/var/log/setup.log"

# Function to log messages to file
log_file() {
    local timestamp=$(date +"%d:%b:%Y, %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Function to log messages using Syslog
log_syslog() {
    local timestamp=$(date +"%d:%b:%Y, %H:%M:%S")
    echo "$timestamp $1" | sudo tee -a /dev/null | sudo logger -p local0.notice
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

# Disable root login via SSH
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo service ssh restart

# Change SSH port and configure UFW rules to port 4450, but feel free to modify based on your preferences
sudo sed -i 's/#Port 22/Port 4450/' /etc/ssh/sshd_config
sudo ufw allow 4450
sudo ufw reload

log_file "SSH configuration completed."

##########################
# System Security
##########################

log_file "Configuring system security..."

# Enable MOTD banner
sudo apt-get install -y figlet
sudo tee -a /etc/motd > /dev/null << EOF
*********************************************************************
*                  WARNING: UNAUTHORIZED ACCESS IS NOT PERMITTED    *
*********************************************************************
EOF

# Removal of legacy services
sudo apt-get purge apache2* mysql-server* perl* php* tomcat8*
sudo apt-get --purge remove telnet-server rsh-server rexec-server talk ntalk xinetd inetd tftp-server ypserv rsh talk-server telnet ldap-utils openldap-clients

# Install and configure Fail2Ban
sudo apt-get install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo tee -a /etc/fail2ban/jail.local > /dev/null << EOF
[sshd]
enabled = true
port = 4450
maxretry = 5
bantime = 3600
EOF
sudo systemctl restart fail2ban

# Enable automatic security updates
sudo apt-get install -y unattended-upgrades
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Enable cron job for automatic updates
sudo tee /etc/apt/apt.conf.d/10periodic > /dev/null << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "0";
EOF

log_file "System security configuration completed."

##########################
# Firewall Configuration
##########################

log_file "Configuring firewall..."

# Configure UFW limits
sudo tee -a /etc/sysctl.conf > /dev/null << EOF
net.core.somaxconn = 1024
fs.file-max = 65536
EOF
sudo sysctl -p

# Enable UFW firewall
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 4450
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

log_file "Firewall configuration completed."

# Update all software
sudo apt-get update
sudo apt-get upgrade

# Set Singapore based timezone
sudo timedatectl set-timezone Asia/Singapore

# Set timestamp format
sudo sed -i 's/#\s*export\s*PS1=/export PS1=/g' ~/.bashrc
sudo sed -i 's/\s*export\s*PS1=/&"\\[\\033[01;34m\\]\\A\\[\\033[00m\\] "/' ~/.bashrc

log_file "Setup complete! Please check the log file ($LOG_FILE) for any errors or warnings."

# Reboot the instance to apply all changes
sudo reboot
