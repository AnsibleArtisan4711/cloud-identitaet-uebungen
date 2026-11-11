# Quelle: Skript „M365 Governance“, Modul 07, Listing 76 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Fall,
    [Parameter(Mandatory)][string[]]$Postfaecher,
    [string[]]$OneDriveUrls = @()
)

Connect-IPPSSession
if (-not (Get-ComplianceCase -Identity $Fall -ErrorAction SilentlyContinue)) {
    New-ComplianceCase -Name $Fall
}

$hold = "$Fall - Sperre"
New-CaseHoldPolicy -Name $hold -Case $Fall `
    -ExchangeLocation $Postfaecher `
    -SharePointLocation $OneDriveUrls -Enabled $true
New-CaseHoldRule -Name "$hold - Regel" -Policy $hold   # ohne Abfrage: alles halten

Get-CaseHoldPolicy -Identity $hold -DistributionDetail |
    Select-Object Name, Enabled, DistributionStatus
