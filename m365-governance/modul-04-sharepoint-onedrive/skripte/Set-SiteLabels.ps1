# Quelle: Skript „M365 Governance“, Modul 04, Listing 30 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$LabelId,       # GUID des Labels
    [string]$UrlPrefix = "/sites/PRJ-",
    [switch]$Ausfuehren
)
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$sites = Get-SPOSite -Limit All -IncludePersonalSite $false
$ohne  = $sites | Where-Object { -not $_.SensitivityLabel }
"{0} von {1} Websites ohne Label." -f $ohne.Count, $sites.Count

$ziel = $ohne | Where-Object { $_.Url -like "*$UrlPrefix*" }
foreach ($s in $ziel) {
    if ($Ausfuehren) {
        Set-SPOSite -Identity $s.Url -SensitivityLabel $LabelId
        "Label gesetzt: $($s.Url)"
    } else {
        "PROBELAUF: $($s.Url)"
    }
}
