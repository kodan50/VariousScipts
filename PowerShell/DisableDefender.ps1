# Requires admin privileges
Write-Host "Disabling Windows Defender's active protections..." -ForegroundColor Yellow

Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableScriptScanning $true

Write-Host "Defender's active protections are now disabled." -ForegroundColor Green


# Requires admin privileges
Write-Host "Attempting full shutdown of Defender's active protections..." -ForegroundColor Yellow

# Disable real-time and behavioral protections
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableScriptScanning $true

# Disable cloud protection and sample submission
Set-MpPreference -MAPSReporting Disabled
Set-MpPreference -SubmitSamplesConsent 2
Set-MpPreference -DisableBlockAtFirstSeen $true
Set-MpPreference -DisableScanningNetworkFiles $true
Set-MpPreference -DisableIntrusionPreventionSystem $true
Set-MpPreference -DisablePrivacyMode $true
Set-MpPreference -DisableRestorePoint $true

# Disable automatic remediation
Set-MpPreference -DisableAutoExclusions $true
Set-MpPreference -DisableArchiveScanning $true
Set-MpPreference -DisableEmailScanning $true
Set-MpPreference -DisableRemediation $true

Write-Host "All configurable Defender protections have been disabled." -ForegroundColor Green


# Requires admin privileges
Write-Host "Applying registry lockdown to disable Windows Defender..." -ForegroundColor Yellow

# Disable Defender via registry
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1

# Disable real-time protection
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 1

# Disable Defender services (optional, may be ignored if Tamper Protection is active)
Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue

Write-Host "Registry lockdown applied. Reboot required to finalize Defender shutdown." -ForegroundColor Green


# Requires admin privileges
Write-Host "Enforcing Defender shutdown via Group Policy registry keys..." -ForegroundColor Yellow

# Disable Microsoft Defender Antivirus
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1

# Disable Real-Time Protection sub-options
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 1

# Optional: Disable Defender Scheduled Scans
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name "DisableScheduleScan" -Value 1

Write-Host "Registry-based Group Policy enforcement applied. Reboot required." -ForegroundColor Green
