$clSite = "{MYTENANT}.sharepoint.com/sites/{LPSite}"
$clientID = "{CLIENTID}"
Write-Host "Learning Pathways Site: ${clSite}"
# Url: the URL of the https endpoint that will be called with a post request including payload
# AnonymizeUser: Default is true, set to false to send unhashed usernames in payload
# KeyHeader: (Optional) An optional custom header that will be sent with the post request, default is "M365LP-API-KEY"
# Key: (Optional) An optional custom header value to be sent with the post request, default is null
$webhookConfig = '{"Url": "https://prod-205.westeurope.logic.azure.com:443/workflows/1af650d8ded24b7593e7522613614c77/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=nkIqFcmFmUVdcYOeRHraES_W7ZIP2ixlstvS7a9H_IU", "AnonymizeUser": true, "KeyHeader": "", "Key": ""}'

#Connect to SharePoint Online Tenant Admin portal
Connect-PnPOnline -Url $clSite -Interactive -ClientId $clientID

#Get Tenant App Catalog
$appCatalogUrl = Get-PnPTenantAppCatalogUrl

if ($appCatalogUrl) {
  # Validate if tenant app catalog Custom scripts is blocked
  try {
    $noScript = $false
    $siteInfo = Get-PnPTenantSite -Url $appCatalogUrl
    if ($siteInfo.DenyAddAndCustomizePages -ne "Disabled") { 
      # Enable custom scripts on the tenant app catalog (allowed)
      Set-PnPTenantSite -Identity $appCatalogUrl -DenyAddAndCustomizePages:$false
      $noScript = $true
    }
  } catch { }

  Set-PnPStorageEntity -Key MicrosoftCustomLearningWebhookConfig -Value $webhookConfig -Description "Microsoft 365 learning pathways webhook configuration"

  Get-PnPStorageEntity -Key MicrosoftCustomLearningWebhookConfig

  # Revert to original setting (blocked)
  try {
    if($noScript -eq $true) {
      Set-PnPTenantSite -Identity $appCatalogUrl -DenyAddAndCustomizePages:$true
    }
  } catch { }
}