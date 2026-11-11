# Quelle: Skript „M365 Governance“, Modul 09, Listing 107 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "AuditLog.Read.All","Directory.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")

$signin = Get-MgAuditLogSignIn -Filter "createdDateTime ge $seit" -Top 1
$audit  = Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge $seit" -Top 1

function Ergebnis($name, $objekt) {
    "{0,-28} {1}" -f $name, $(if ($objekt) { "OK (Eintraege vorhanden)" } else { "HINWEIS: keine Eintraege in 24 h" })
}

Ergebnis "Anmeldeprotokoll" $signin
Ergebnis "Verzeichnis-Audit"  $audit

$riskant = Get-MgRiskyUser -Filter "riskState eq 'atRisk'" -ErrorAction SilentlyContinue
"Benutzer mit Risiko (atRisk): {0}" -f @($riskant).Count
