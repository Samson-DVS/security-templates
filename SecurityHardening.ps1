#Author: Visahl Samson

# Log File Path
$logFile = "C:\Windows\Temp\SecurityHardeningLog.txt"

# Function to log output
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $message"
    Write-Host $entry
    Add-Content -Path $logFile -Value $entry
}

# Create a System Restore Point
try {
    powershell.exe -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'BeforeSecurityHardening' -RestorePointType 'MODIFY_SETTINGS'"
    Log-Message "System Restore Point created successfully."
} catch {
    Log-Message "Failed to create System Restore Point: $_"
}

# Disable Guest Account
try {
    net user guest /active:no
    Log-Message "Guest account disabled."
} catch {
    Log-Message "Failed to disable Guest account: $_"
}

# Set Password Policy
try {
    net accounts /minpwlen:15 /maxpwage:90 /minpwage:1 /uniquepw:5
    Log-Message "Password policy set successfully."
} catch {
    Log-Message "Failed to set Password policy: $_"
}

# Enable Windows Defender
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Log-Message "Windows Defender real-time monitoring enabled."
} catch {
    Log-Message "Failed to enable Windows Defender: $_"
}

# Enable Firewall
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Log-Message "Firewall enabled on all profiles."
} catch {
    Log-Message "Failed to enable Firewall: $_"
}

# Disable SMBv1
try {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    Log-Message "SMBv1 disabled."
} catch {
    Log-Message "Failed to disable SMBv1: $_"
}

# Enable BitLocker (requires TPM)
try {
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnlyEncryption
    Log-Message "BitLocker enabled with AES256 encryption."
} catch {
    Log-Message "Failed to enable BitLocker: $_"
}

# Disable Remote Desktop
try {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 1
    Log-Message "Remote Desktop disabled."
} catch {
    Log-Message "Failed to disable Remote Desktop: $_"
}

# Configure Account Lockout Policy
try {
    $secpolFile = "C:\Windows\Temp\secpol.cfg"
    secedit /export /cfg $secpolFile /areas SECURITYPOLICY
    Add-Content $secpolFile "AccountLockoutBadCount = 5"
    Add-Content $secpolFile "AccountLockoutDuration = 15"
    Add-Content $secpolFile "ResetLockoutCount = 15"
    secedit /import /cfg $secpolFile /areas SECURITYPOLICY
    Log-Message "Account Lockout Policy configured successfully."
} catch {
    Log-Message "Failed to configure Account Lockout Policy: $_"
}

# Disable Unused Services (Fax)
try {
    Stop-Service -Name "Fax" -Force
    Set-Service -Name "Fax" -StartupType Disabled
    Log-Message "Fax service disabled."
} catch {
    Log-Message "Failed to disable Fax service: $_"
}

# Configure Windows Update to Automatic
try {
    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv
    Log-Message "Windows Update set to Automatic."
} catch {
    Log-Message "Failed to configure Windows Update: $_"
}

# Enable Audit Policy
try {
    auditpol /set /category:* /success:enable /failure:enable
    Log-Message "Audit policy enabled for all categories."
} catch {
    Log-Message "Failed to enable Audit policy: $_"
}

# Disable File and Printer Sharing
try {
    Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled False
    Log-Message "File and Printer Sharing disabled."
} catch {
    Log-Message "Failed to disable File and Printer Sharing: $_"
}

# Enable User Account Control (UAC)
try {
    Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name "EnableLUA" -Value 1
    Log-Message "User Account Control (UAC) enabled."
} catch {
    Log-Message "Failed to enable UAC: $_"
}

# Set Windows Defender to scan automatically
try {
    Set-MpPreference -ScanScheduleDay 0 -ScanScheduleTime 2
    Log-Message "Windows Defender scheduled for automatic scanning every Sunday at 2 AM."
} catch {
    Log-Message "Failed to schedule Windows Defender scanning: $_"
}

# Remove unnecessary file associations to mitigate ransomware risks
try {
    assoc .bat=txtfile
    assoc .cmd=txtfile
    assoc .vbs=txtfile
    Log-Message "Unnecessary file associations removed."
} catch {
    Log-Message "Failed to remove unnecessary file associations: $_"
}

# Configure Windows Security Settings
try {
    Set-MpPreference -DisableIntrusionPreventionSystem $false
    Log-Message "Windows Intrusion Prevention System (IPS) enabled."
} catch {
    Log-Message "Failed to enable IPS: $_"
}

# Restart Prompt
$restart = Read-Host "Some changes may require a restart. Do you want to restart the computer now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Restart-Computer -Force
} else {
    Log-Message "Script completed. Restart was skipped."
}

# Final Message
Log-Message "Security hardening script completed successfully."
Write-Host "Script execution completed. Check the log file at $logFile for details."
