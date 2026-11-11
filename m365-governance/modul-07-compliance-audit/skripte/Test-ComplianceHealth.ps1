# Quelle: Skript „M365 Governance“, Modul 07, Listing 80 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline
Connect-IPPSSession
function Zeile($name, $ok, $info) {
    "{0,-34} {1,-8} {2}" -f $name, $(if ($ok) { "OK" } else { "HINWEIS" }), $info
}

$cfg = Get-AdminAuditLogConfig
Zeile "Audit-Erfassung" $cfg.UnifiedAuditLogIngestionEnabled `
      "UnifiedAuditLogIngestionEnabled = $($cfg.UnifiedAuditLogIngestionEnabled)"

$probe = Search-UnifiedAuditLog -StartDate (Get-Date).ToUniversalTime().AddDays(-1) `
         -EndDate (Get-Date).ToUniversalTime() -ResultSize 5
Zeile "Audit-Eintraege letzte 24 h" (@($probe).Count -gt 0) "Treffer in Stichprobe: $(@($probe).Count)"

$faelle = Get-ComplianceCase | Where-Object Status -eq "Active"
Zeile "Aktive eDiscovery-Faelle" $true "$(@($faelle).Count) aktiv"

$holds = Get-CaseHoldPolicy -DistributionDetail
$schlecht = $holds | Where-Object { $_.DistributionStatus -ne "Success" }
Zeile "Sperrrichtlinien verteilt" (-not $schlecht) `
      "$(@($holds).Count) gesamt, $(@($schlecht).Count) nicht erfolgreich"
