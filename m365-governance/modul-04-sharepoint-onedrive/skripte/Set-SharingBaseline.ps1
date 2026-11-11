# Quelle: Skript „M365 Governance“, Modul 04, Listing 29 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

# 1) Tenant-Standard setzen
Set-SPOTenant -SharingCapability ExternalUserSharingOnly `
              -DefaultSharingLinkType Direct `
              -RequireAnonymousLinksExpireInDays 30 `
              -ExternalUserExpirationRequired $true `
              -ExternalUserExpireInDays 60

# 2) Aktuellen Zustand lesen
$t = Get-SPOTenant
"Tenant-Freigabe: {0}" -f $t.SharingCapability

# 3) Verteilung der Websites nach eigener Einstellung
Get-SPOSite -Limit All |
    Select-Object Url, Title, SharingCapability, Owner |
    Group-Object SharingCapability |
    Select-Object Name, Count | Format-Table -AutoSize
