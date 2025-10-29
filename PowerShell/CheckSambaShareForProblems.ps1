# Check network profile
$profile = Get-NetConnectionProfile
Write-Host "Network Profile: $($profile.Name) - $($profile.NetworkCategory)"

# Check if Network Discovery is enabled
$ndRules = Get-NetFirewallRule -DisplayGroup "Network Discovery" | Where-Object {$_.Enabled -eq "True"}
if ($ndRules) {
    Write-Host "Network Discovery is enabled."
} else {
    Write-Host "Network Discovery is disabled."
}

# Check if File and Printer Sharing is enabled
$fpsRules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Where-Object {$_.Enabled -eq "True"}
if ($fpsRules) {
    Write-Host "File and Printer Sharing is enabled."
} else {
    Write-Host "File and Printer Sharing is disabled."
}

# Check SMB client settings
$smbClient = Get-SmbClientConfiguration
Write-Host "RequireSecuritySignature: $($smbClient.RequireSecuritySignature)"
Write-Host "EnableSecuritySignature: $($smbClient.EnableSecuritySignature)"
Write-Host "EnablePlainTextPassword: $($smbClient.EnablePlainTextPassword)"

# Check if guest access is allowed
$guestAccess = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestLogons" -ErrorAction SilentlyContinue
if ($guestAccess.AllowInsecureGuestLogons -eq 1) {
    Write-Host "Guest access is allowed."
} else {
    Write-Host "Guest access is blocked."
}

# Test connectivity to Samba server (replace with your server IP)
$serverIP = "192.168.1.2"
Test-Connection -ComputerName $serverIP -Count 2

# Try listing shares (requires credentials if not guest)
# Replace with your Samba server IP and credentials
# net view \\192.168.1.2

Write-Host "Diagnostics complete. Review results above to identify any misconfigurations."
