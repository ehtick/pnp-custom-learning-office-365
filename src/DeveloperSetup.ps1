$clSite = "https://contoso.sharepoint.com/sites/M365LP"

try {
  Connect-PnPOnline -Url $clSite -UseWebLogin

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

  Set-PnPStorageEntity -Key MicrosoftCustomLearningCdn -Value "https://pnp.github.io/custom-learning-office-365/learningpathways/" -Description "CDN source for Microsoft 365 learning pathways Content"
  Get-PnPStorageEntity -Key MicrosoftCustomLearningCdn
  Set-PnPStorageEntity -Key MicrosoftCustomLearningSite -Value $clSite -Description "M365 learning pathways Site Collection"
  Get-PnPStorageEntity -Key MicrosoftCustomLearningSite
  Set-PnPStorageEntity -Key MicrosoftCustomLearningTelemetryOn -Value $true -Description "M365 learning pathways Telemetry Collection"
  Get-PnPStorageEntity -Key MicrosoftCustomLearningTelemetryOn

  # Revert to original setting (blocked)
  try {
    if($noScript -eq $true) {
      Set-PnPTenantSite -Identity $appcatalog -DenyAddAndCustomizePages:$true
    }
  } catch { }

  $clv = Get-PnPListItem -List "Site Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>CustomLearningViewer.aspx</Value></Eq></Where></Query></View>"
  if ($clv -eq $null) {
    $clvPage = Add-PnPClientSidePage "CustomLearningViewer"
    $clvSection = Add-PnPClientSidePageSection -Page $clvPage -SectionTemplate OneColumn -Order 1
    Add-PnPClientSideWebPart -Page $clvPage -Component "Microsoft 365 learning pathways"
    Set-PnPClientSidePage -Identity $clvPage -Publish
    $clv = Get-PnPListItem -List "Site Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>CustomLearningViewer.aspx</Value></Eq></Where></Query></View>"
  }
  $clv["PageLayoutType"] = "SingleWebPartAppPage"
  $clv.Update()
  Invoke-PnPQuery
    
  $cla = Get-PnPListItem -List "Site Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>CustomLearningAdmin.aspx</Value></Eq></Where></Query></View>"
  if ($cla -eq $null) {
    $claPage = Add-PnPClientSidePage "CustomLearningAdmin" -Publish
    $claSection = Add-PnPClientSidePageSection -Page $claPage -SectionTemplate OneColumn -Order 1
    Add-PnPClientSideWebPart -Page $claPage -Component "Microsoft 365 learning pathways administration"
    Set-PnPClientSidePage -Identity $claPage -Publish
    $cla = Get-PnPListItem -List "Site Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>CustomLearningAdmin.aspx</Value></Eq></Where></Query></View>"
  }
  $cla["PageLayoutType"] = "SingleWebPartAppPage"
  $cla.Update()
  Invoke-PnPQuery
    
}
catch {
  Write-Error "Failed to authenticate to $siteUrl"
  Write-Error $_.Exception

  # Revert to original setting (blocked)
  try {
    if($noScript -eq $true) {
      Set-PnPTenantSite -Identity $appcatalog -DenyAddAndCustomizePages:$true
    }
  } catch { }
}

