# Quelle: Skript „M365 Governance“, Modul 04, Listing 33 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$SiteUrl)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$s = Get-SPOSite -Identity $SiteUrl -Detailed
[pscustomobject]@{
    Url              = $s.Url
    Titel            = $s.Title
    Vorlage          = $s.Template
    Sperrstatus      = $s.LockState
    Freigabe         = $s.SharingCapability
    Label            = $s.SensitivityLabel
    HubId            = $s.HubSiteId
    GenutztGB        = [math]::Round($s.StorageUsageCurrent / 1024, 2)
    QuoteGB          = [math]::Round($s.StorageQuota / 1024, 2)
    LetzteAenderung  = $s.LastContentModifiedDate
    Besitzer         = $s.Owner
} | Format-List

"`nSharePoint-Gruppen:"
Get-SPOSiteGroup -Site $SiteUrl | Select-Object Title, @{n='Rolle';e={$_.Roles -join ', '}}, @{n='Mitglieder';e={$_.Users.Count}} | Format-Table -AutoSize
