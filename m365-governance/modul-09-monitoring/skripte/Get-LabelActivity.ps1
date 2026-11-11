# Quelle: Skript „M365 Governance“, Modul 09, Listing 102 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Tage = 7)

Connect-ExchangeOnline

$ops   = "SensitivityLabelApplied", "SensitivityLabelUpdated", "SensitivityLabelRemoved",
         "FileSensitivityLabelApplied", "FileSensitivityLabelChanged", "FileSensitivityLabelRemoved"
$ende  = (Get-Date).ToUniversalTime()
$start = $ende.AddDays(-$Tage)
$treffer = Search-UnifiedAuditLog -StartDate $start -EndDate $ende -Operations $ops `
    -ResultSize 5000 -SessionId ("lbl-" + (Get-Date -Format yyyyMMddHHmmss)) -SessionCommand ReturnLargeSet

if (-not $treffer) { Write-Host "Keine Label-Aktivitaet gefunden (Operationsnamen pruefen)."; return }

$treffer | Group-Object Operations | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

if (@($treffer).Count -ge 5000) {
    Write-Warning "5000 Treffer erreicht: Zeitraum verkleinern, die Zahl ist moeglicherweise unvollstaendig."
}
