# Quelle: Skript „M365 Governance“, Modul 07, Listing 68 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Fall,
    [Parameter(Mandatory)][string]$Postfach,
    [Parameter(Mandatory)][string]$Stichwort,
    [Parameter(Mandatory)][string]$Von,      # z. B. 2026-01-01
    [Parameter(Mandatory)][string]$Bis       # z. B. 2026-06-30
)

Connect-IPPSSession

if (-not (Get-ComplianceCase -Identity $Fall -ErrorAction SilentlyContinue)) {
    New-ComplianceCase -Name $Fall -Description "Angelegt per Skript, Genehmigung siehe Ticket"
}

$abfrage = "($Stichwort) AND (Date>=$Von) AND (Date<=$Bis)"
New-ComplianceSearch -Name "$Fall - Suche 1" -Case $Fall `
    -ExchangeLocation $Postfach -ContentMatchQuery $abfrage
Start-ComplianceSearch -Identity "$Fall - Suche 1"

do {
    Start-Sleep -Seconds 15
    $s = Get-ComplianceSearch -Identity "$Fall - Suche 1"
} while ($s.Status -ne "Completed")

"{0}: {1} Elemente, {2} Bytes" -f $s.Name, $s.Items, $s.Size
