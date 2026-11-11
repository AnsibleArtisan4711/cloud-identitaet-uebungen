# Quelle: Skript „M365 Governance“, Modul 08, Listing 96 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Benutzer,
    [int]$Stunden = 24
)

Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddHours(-$Stunden).ToString("yyyy-MM-ddTHH:mm:ssZ")
$logs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$Benutzer' and createdDateTime ge $seit" -Top 25

if (-not $logs) { Write-Host "Keine Anmeldungen im Zeitraum."; return }

foreach ($l in $logs | Sort-Object CreatedDateTime) {
    "{0:u}  {1}  CA-Status: {2}  Fehlercode: {3}" -f $l.CreatedDateTime, $l.AppDisplayName,
        $l.ConditionalAccessStatus, $l.Status.ErrorCode
    foreach ($p in $l.AppliedConditionalAccessPolicies) {
        "      - {0}: {1}" -f $p.DisplayName, $p.Result
    }
    if ($l.Status.FailureReason) { "      Grund: " + $l.Status.FailureReason }
}
