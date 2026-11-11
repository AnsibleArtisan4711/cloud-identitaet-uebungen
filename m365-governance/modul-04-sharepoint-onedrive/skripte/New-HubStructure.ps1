# Quelle: Skript „M365 Governance“, Modul 04, Listing 27 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$hub = "https://contoso.sharepoint.com/sites/HUB-Projekte"

# 1) Hub registrieren (falls noch nicht geschehen)
if (-not (Get-SPOHubSite -Identity $hub -ErrorAction SilentlyContinue)) {
    Register-SPOHubSite -Site $hub | Out-Null
    Set-SPOHubSite -Identity $hub -Title "Projekte" | Out-Null
}

# 2) Websites anschliessen
$kandidaten = Get-SPOSite -Limit All -Filter "Url -like '/sites/PRJ-'"
foreach ($s in $kandidaten) {
    Add-SPOHubSiteAssociation -Site $s.Url -HubSite $hub
    "Angeschlossen: $($s.Url)"
}

# 3) Uebersicht
Get-SPOHubSite | Select-Object Title, SiteUrl | Format-Table -AutoSize
