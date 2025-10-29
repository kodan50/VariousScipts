# Add Downloads folder to Windows Defender exclusion list
$downloadsPath = "$env:USERPROFILE\Downloads"

# Check if the path exists
if (Test-Path $downloadsPath) {
    Write-Host "Adding $downloadsPath to Defender exclusions..."
    Add-MpPreference -ExclusionPath $downloadsPath
    Write-Host "Done. Downloads folder is now excluded from Defender scans."
} else {
    Write-Host "Error: Downloads folder not found at $downloadsPath"
}
