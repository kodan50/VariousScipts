Get-ChildItem C:\Windows\System32\CodeIntegrity\CiPolicies\Active\*.cip | ForEach-Object {
    # Convert the policy to XML to view its contents (more readable)
    $PolicyPath = $_.FullName
    $PolicyXML = ($PolicyPath -replace '\.cip$', '.xml')
    ConvertFrom-CIPolicy -FilePath $PolicyPath -XmlFilePath $PolicyXML

    Write-Host "`nPolicy File: $($_.Name)"
    Write-Host "Policy Path: $($_.FullName)"
    Write-Host "Policy XML: $PolicyXML"
    Write-Host "--- Policy Details (from XML) ---"
    Get-Content $PolicyXML | Select-String "PolicyID", "BasePolicyID", "AuditMode", "Enabled:" | Format-List
    Remove-Item $PolicyXML # Clean up the temporary XML file
    Write-Host "----------------------------------"
}
