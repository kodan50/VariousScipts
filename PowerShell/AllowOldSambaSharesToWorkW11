# Enable SMBv1
Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart

# Enable Network Discovery and File Sharing
Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True

# Set network profile to Private (required for discovery and sharing)
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Allow guest access to SMB shares (if your Samba server uses guest access)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestLogons" -Value 1

# Restart Workstation service to apply changes
Restart-Service -Name "LanmanWorkstation"
