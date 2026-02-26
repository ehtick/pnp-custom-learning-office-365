param([string]$TenantName,
  [string]$ClientID)

try {
  $NotFound = $true
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = ‘stop’
  # verify the PnP cmdlets we need are installed
  if (Get-Command Connect-PnPOnline ) {
    Write-Host "Found PnP Command"
    $NotFound = $false
  }

}
catch {
  Write-Warning "Could not find PnP PowerShell cmdlets"
  Write-Warning "Please install them and run this script again"
  Write-Warning "You can install them with the following line:"
  Write-Warning "`nInstall-Module PnP.PowerShell`n"

}
finally {
  $ErrorActionPreference = $oldPreference
  if ($NotFound) { exit }
}

# Check if tenant name was passed in
if ([string]::IsNullOrWhitespace($TenantName)) {
  # No TenantName was passed, prompt the user
  $TenantName = Read-Host "Please enter your tenant name: (contoso) "
}
# Check if clientID was passed in
if ([string]::IsNullOrWhitespace($ClientID)) {
  # No TenantName was passed, prompt the user
  $ClientID = Read-Host "Please enter a clientID: (3f78e14b-8ad4-4a29-a77b-3f5421d61d41) "
}
$AdminURL = "https://$TenantName.sharepoint.com"

# Connect to Admin site.
# Todo: Differentiate between valid $adminurl and authentication error (bad password or no access)
try {
  Connect-PnPOnline -Url $AdminURL -Interactive -ClientId $ClientID -ErrorAction Stop
}
catch {
  Write-Warning "Failed to authenticate to $AdminURL"
  Write-Warning $_
  break
}

# Validate if tenant app catalog Custom scripts is blocked
try {
  $appcatalog = Get-PnPTenantAppCatalogUrl

  $noScript = $false
  $siteInfo = Get-PnPTenantSite -Url $appcatalog
  if ($siteInfo.DenyAddAndCustomizePages -ne "Disabled") { 
    # Enable custom scripts on the tenant app catalog (allowed)
    Set-PnPTenantSite -Identity $appcatalog -DenyAddAndCustomizePages:$false
    $noScript = $true
  }
} catch { }

Set-PnPStorageEntity -Key MicrosoftCustomLearningCdn -Value "https://pnp.github.io/custom-learning-office-365/learningpathways/" -Description "Microsoft 365 learning pathways CDN source" -ErrorAction Stop
Get-PnPStorageEntity -Key MicrosoftCustomLearningCdn

# Revert to original setting (blocked)
try {
  if($noScript -eq $true) {
    Set-PnPTenantSite -Identity $appcatalog -DenyAddAndCustomizePages:$true
  }
} catch { }

Disconnect-PnPOnline
