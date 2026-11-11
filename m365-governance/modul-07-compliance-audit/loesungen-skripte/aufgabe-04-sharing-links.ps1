# Quelle: Skript „M365 Governance“, Modul 07, Lösung zu Aufgabe 4 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline
$ende = (Get-Date).ToUniversalTime(); $start = $ende.AddDays(-3)
Search-UnifiedAuditLog -StartDate $start -EndDate $ende `
    -Operations SharingLinkCreated -ResultSize 5000 |
  ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{ Zeit = $_.CreationDate; Benutzer = $_.UserIds
                       Datei = $d.SourceFileName }
  } | Sort-Object Zeit | Format-Table -AutoSize
