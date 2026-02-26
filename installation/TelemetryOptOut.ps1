param([string]$TenantName,
  [string]$ClientID)

# verify the PnP cmdlets we need are installed
if (-not (Get-Command Connect-PnPOnline -ErrorAction SilentlyContinue )) {
  Write-Warning "Could not find PnP PowerShell cmdlets"
  Write-Warning "Please install them and run this script again"
  Write-Warning "You can install them with the following line:"
  Write-Warning "`nInstall-Module SharePointPnPPowerShellOnline`n"
  break
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
# 2/6/20 Removed -Credential and replaced it with -UseWebLogin to support MFA. -tk
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
    
Set-PnPStorageEntity -Key MicrosoftCustomLearningTelemetryOn -Value $false -Description "Microsoft 365 learning pathways Telemetry Setting"
Get-PnPStorageEntity -Key MicrosoftCustomLearningTelemetryOn

# Revert to original setting (blocked)
try {
  if($noScript -eq $true) {
    Set-PnPTenantSite -Identity $appcatalog -DenyAddAndCustomizePages:$true
  }
} catch { }

Disconnect-PnPOnline
