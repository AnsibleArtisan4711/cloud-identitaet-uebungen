# Quelle: Skript „M365 Governance“, Modul 04, Listing 26 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Tenant,       # z. B. "contoso"
    [Parameter(Mandatory)][string]$Name,         # URL-Teil, z. B. "ABT-Personal-Intranet"
    [Parameter(Mandatory)][string]$Titel,
    [Parameter(Mandatory)][string]$Besitzer      # UPN des Besitzers
)

Connect-SPOService -Url "https://$Tenant-admin.sharepoint.com"

$url = "https://$Tenant.sharepoint.com/sites/$Name"
if (Get-SPOSite -Identity $url -ErrorAction SilentlyContinue) {
    throw "Website existiert bereits: $url"
}

New-SPOSite -Url $url -Title $Titel -Owner $Besitzer `
            -Template "SITEPAGEPUBLISHING#0" -StorageQuota 1024 -NoWait

# Voreinstellung: keine externe Freigabe
Start-Sleep -Seconds 20
Set-SPOSite -Identity $url -SharingCapability Disabled
"Website angelegt (oder in Arbeit): $url"
